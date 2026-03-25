import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../utils/log_util.dart';

class DtwTemplate {
  final String name;
  final int targetLen;
  final int featureDim;
  final List<int> trim;
  final List<double> mean;
  final List<double> std;
  final List<List<double>> features; // raw (not standardized)

  const DtwTemplate({
    required this.name,
    required this.targetLen,
    required this.featureDim,
    required this.trim,
    required this.mean,
    required this.std,
    required this.features,
  });

  List<List<double>> standardizedFeatures() {
    return features
        .map((row) => List<double>.generate(
              featureDim,
              (i) => (row[i] - mean[i]) / (std[i] == 0 ? 1.0 : std[i]),
              growable: false,
            ))
        .toList(growable: false);
  }

  static DtwTemplate fromJson(Map<String, dynamic> json) {
    return DtwTemplate(
      name: json['name'] as String,
      targetLen: (json['target_len'] as num).toInt(),
      featureDim: (json['feature_dim'] as num).toInt(),
      trim: (json['trim'] as List<dynamic>).map((e) => (e as num).toInt()).toList(growable: false),
      mean: (json['mean'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(growable: false),
      std: (json['std'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(growable: false),
      features: (json['features'] as List<dynamic>)
          .map(
            (row) => (row as List<dynamic>).map((e) => (e as num).toDouble()).toList(growable: false),
          )
          .toList(growable: false),
    );
  }
}

class DtwMatchResult {
  final double similarity; // 0..100
  final bool passed;
  final double dtwDistance;

  const DtwMatchResult({
    required this.similarity,
    required this.passed,
    required this.dtwDistance,
  });
}

enum DtwFeatureMode {
  fullBody,
  keypoints6,
}

class DtwPoseMatcher {
  DtwTemplate? _template;
  late List<List<double>> _templateStd; // standardized
  DtwFeatureMode _featureMode = DtwFeatureMode.fullBody;
  String _actionType = '';
  /// 为 false 时跳过「低位武装 + 起势姿态」门控，特征有效即进入在线 DTW（更早出 acc，误判风险更高）。
  bool _onlineUseStartGating = true;

  // 录制相关
  bool _recording = false;
  final List<List<double>> _userSeq = [];
  int _endLowCount = 0;
  final int _frameSkip = 1; // 在线反馈优先：每帧采样，减少体感延迟
  int _frameCounter = 0;

  // 在线滑动窗口匹配（不需要开始/结束，只要出现匹配片段就通过）
  final List<List<double>> _onlineBuffer = [];
  double? lastSimilarity;
  int _onlinePassStreak = 0;
  bool _onlineStarted = false;
  // 为了避免“手已经抬到上方但还没开始动作”就触发 online 评估，
  // 需要先观测到手腕处于较低高度一段时间，再进入在线评估。
  bool _startArmed = false;
  int _startLowCount = 0;
  int _startPoseStreak = 0; // start pose 命中连续帧数
  static const int _onlineMaxBufferLen = 120; // 允许的最大缓存帧数（已做下采样）
  // 首次评估不要等太久：抬手进入 onlineStarted 后尽快给出第一帧相似度
  static const int _onlineMinBufferLen = 6; // 更短窗口，尽快给首帧反馈
  static const int _onlineEvalEveryFrames = 1; // 每帧都做一次评估
  static const int _onlinePassHoldFrames = 3; // 减少完成判定延迟

  // 调试：只在 DTW 评估点打印
  int _onlineEvalCount = 0;
  double _onlineBestSimilarity = -1.0;
  static const int _onlineDebugPrintEveryEvals = 10;
  int _startBlockedLogSkip = 0;

  // 结束/通过阈值（后续可按实际表现调参）
  final double startWristRelYUp = 0.05;
  // 起始门控以“手腕抬高”作为主条件，肘部仅作宽松辅助，避免抬手后仍迟迟不触发 onlineStarted。
  final double startElbowRelYUp = -0.08;
  final double startWristRelYUpLow = 0.02; // 低于该阈值认为“还没抬起来”
  static const int startLowHoldFrames = 8; // 需要持续低一段时间再“武装”开始门控
  static const int startPoseHoldFrames = 3; // start pose 需要连续成立
  final double endWristRelYUp = 0.01; // wrist_rel_y_up < 0.01 认为“手落下了”
  final int endHoldFrames = 8;
  final int minRecordFrames = 15;
  final int maxRecordFrames = 220;

  // ---------------------------
  // 动作特定“手腕门阀”（基于 *_kp6.json 里手腕 relYUp 分布统计）
  // 说明：relYUp 为“相对鼻子”的 y-up，很多动作的抬手仍可能是负值，
  // 因此不能统一使用 0.05。
  // ---------------------------
  final double _startWristRelYUpStep1 = 0.02;
  final double _passWristRelYUpStep1 = 0.03;

  // 左右开弓：抬起手表现为“更不负”，用负阈值。
  final double _startWristRelYUpStep2 = -0.63;
  final double _passWristRelYUpStep2 = -0.34;

  // 调理脾胃：抬起手分布跨过 0，小幅抬起即可开始，pass 再略提高。
  final double _startWristRelYUpStep3 = 0.00;
  final double _passWristRelYUpStep3 = 0.02;

  // 通过阈值：当前日志中相似度通常只有 6~16（取决于 avgCost 量级）
  // 为了让“能触发通过”先跑通流程，先把阈值下调到 8 左右，后续可基于新日志继续微调。
  // 轨迹检测：不让肘角前两维参与 DTW 距离，并且通过判定不再使用肘角。
  // 实际上你的在线日志里 sim 常落在 40~60；这里先给一个能触发流程的起始阈值。
  final double passSimilarityThreshold = 50.0;

  // 通过时要求手腕相对鼻子的高度足够高（用位置，不用角度）。
  final double passWristRelYUpMin = 0.05;

  // keypoints6 时只用轨迹类维度；fullBody 时用全维度
  final List<int> _trajectoryDims = const [2, 3, 4, 5];

  Future<void> loadTemplateFromAsset({String assetPath = 'assets/video/baduanjin_step1_dtw_template.json'}) async {
    final resolvedAssetPath = await _resolveAssetPathByMode(assetPath);
    final text = await rootBundle.loadString(resolvedAssetPath);
    final jsonMap = jsonDecode(text) as Map<String, dynamic>;
    _template = DtwTemplate.fromJson(jsonMap);
    _templateStd = _template!.standardizedFeatures();
    if (resolvedAssetPath != assetPath) {
      Log.d(
        'DTW: mode=$_featureMode 自动改用模板: $resolvedAssetPath',
        tag: 'DTW',
      );
    }
    if (_featureMode == DtwFeatureMode.keypoints6 && _template!.featureDim != 6) {
      Log.d(
        'DTW: keypoints6 mode with tplDim=${_template!.featureDim},建议切 fullBody 或更换6维模板',
        tag: 'DTW',
      );
    }
    if (_featureMode == DtwFeatureMode.fullBody && _template!.featureDim == 6) {
      Log.d(
        'DTW: fullBody mode with tplDim=6,建议切 keypoints6 或更换全身模板',
        tag: 'DTW',
      );
    }
  }

  Future<String> _resolveAssetPathByMode(String assetPath) async {
    if (_featureMode == DtwFeatureMode.keypoints6 && assetPath.endsWith('.json')) {
      final kp6Path = assetPath.replaceFirst(RegExp(r'\.json$'), '_kp6.json');
      try {
        await rootBundle.loadString(kp6Path);
        return kp6Path;
      } catch (_) {
        Log.d(
          'DTW: keypoints6 模板不存在，回退原模板: $kp6Path',
          tag: 'DTW',
        );
      }
    }
    return assetPath;
  }

  bool get isReady => _template != null;
  bool get isRecording => _recording;
  bool get isOnlineStarted => _onlineStarted;
  DtwFeatureMode get featureMode => _featureMode;

  void setFeatureMode(DtwFeatureMode mode) {
    _featureMode = mode;
    resetRecording();
  }

  void setActionType(String actionType) {
    _actionType = actionType;
  }

  void setOnlineUseStartGating(bool use) {
    _onlineUseStartGating = use;
    resetRecording();
  }

  bool get onlineUseStartGating => _onlineUseStartGating;

  /// 仅对「双手托天 / 左右开弓」要求先观察到双手在低位一段时间，再允许起势；非对称或马步类动作不设此限。
  bool _needsLowHoldBeforeStart() {
    switch (_actionType) {
      case '双手托天':
      case '左右开弓-左':
      case '左右开弓-右':
        return true;
      default:
        return false;
    }
  }

  bool get _useFullBodyByTemplate {
    final dim = _template?.featureDim;
    if (dim == null) return _featureMode == DtwFeatureMode.fullBody;
    return dim > 6;
  }

  void resetRecording() {
    _recording = false;
    _userSeq.clear();
    _endLowCount = 0;
    _frameCounter = 0;

    // 同时重置在线窗口状态
    _onlineStarted = false;
    _startArmed = false;
    _startLowCount = 0;
    _startPoseStreak = 0;
    _onlineBuffer.clear();
    _onlinePassStreak = 0;
    lastSimilarity = null;

    // 重置调试状态
    _onlineEvalCount = 0;
    _onlineBestSimilarity = -1.0;
    _startBlockedLogSkip = 0;
  }

  /// 在线 DTW：只要在当前 pose 流里出现足够匹配的片段，就返回一次完成结果（passed=true）。
  /// 返回 null 表示尚未检测到足够匹配的片段。
  DtwMatchResult? updateOnline(Pose pose) {
    if (_template == null) return null;

    final vecRaw = extractFeatureVector(pose);
    if (vecRaw == null) return null;

    // 门控：仅在检测到“开始做第一式”后，才进入在线窗口评估
    if (!_onlineStarted) {
      if (!_onlineUseStartGating) {
        _onlineStarted = true;
        _onlineBuffer.clear();
        _onlinePassStreak = 0;
        _frameCounter = 0;
        _startArmed = false;
        _startLowCount = 0;
        _startPoseStreak = 0;
        Log.d('DTW: onlineStarted=true (start gating off)', tag: 'DTW');
      } else {
      // 先确认：手腕要“从低处抬起来”，而不是已经在高位直接开始算相似度。
      final wristRel = _wristRelYUpFromPose(pose);
      if (wristRel == null) return null;
      final leftWristRelYUp = wristRel.$1;
      final rightWristRelYUp = wristRel.$2;

      if (_needsLowHoldBeforeStart()) {
        final lowNow = leftWristRelYUp < startWristRelYUpLow && rightWristRelYUp < startWristRelYUpLow;
        if (lowNow) {
          _startLowCount++;
          if (_startLowCount >= startLowHoldFrames) {
            _startArmed = true;
            _startPoseStreak = 0;
          }
        } else {
          _startLowCount = 0;
        }
        if (!_startArmed) return null;
      } else {
        // 调理脾胃 / 摇头摆尾等：不要求双手先同时低位，避免一辈子武装不上。
        _startArmed = true;
      }

      final startOk = _isStartPose(pose);
      if (!startOk) {
        _startBlockedLogSkip++;
        if (_startBlockedLogSkip % 12 == 0) {
          Log.d(
            'DTW: start blocked action=$_actionType '
            'lwRel=${leftWristRelYUp.toStringAsFixed(3)} '
            'rwRel=${rightWristRelYUp.toStringAsFixed(3)}',
            tag: 'DTW',
          );
        }
        _startPoseStreak = 0;
        return null;
      }

      _startPoseStreak++;
      if (_startPoseStreak < startPoseHoldFrames) {
        return null;
      }

      _onlineStarted = true;
      _onlineBuffer.clear();
      _onlinePassStreak = 0;
      _frameCounter = 0;
      _startArmed = false;
      _startLowCount = 0;
      _startPoseStreak = 0;
      Log.d(
        'DTW: onlineStarted=true (start pose stabilized) '
        'lwRel=${leftWristRelYUp.toStringAsFixed(3)} rwRel=${rightWristRelYUp.toStringAsFixed(3)}',
        tag: 'DTW',
      );
      }
    }

    // 下采样 + 入队
    if (_frameCounter % _frameSkip == 0) {
      _onlineBuffer.add(_standardizeVector(vecRaw));
      if (_onlineBuffer.length > _onlineMaxBufferLen) {
        _onlineBuffer.removeAt(0);
      }
    }
    _frameCounter++;

    // 控制评估频率（避免每帧都算 DTW）
    if (_onlineBuffer.length < _onlineMinBufferLen) return null;
    if (_frameCounter % _onlineEvalEveryFrames != 0) return null;

    // 取最近一段做评估：长度越小越快，但过短可能影响稳定性
    final takeLen = math.min(_onlineBuffer.length, _onlineMaxBufferLen);
    final windowSeq = _onlineBuffer.sublist(_onlineBuffer.length - takeLen);

    final resized = _resampleToTargetLen(windowSeq, _template!.targetLen);
    final dist = dtwDistance(
      resized,
      _templateStd,
      window: 18,
      dimsToUse: _useFullBodyByTemplate ? null : _trajectoryDims,
    );

    final avgCost = dist / (resized.length + _templateStd.length);
    // 更平滑的相似度映射：避免 exp 在 avgCost 稍大时下溢到 1e-100 级别
    final similarity = 100.0 / (1.0 + avgCost / 50.0);
    lastSimilarity = similarity.isFinite ? similarity.clamp(0.0, 100.0) : 0.0;

    // ===== 调试日志（只在真正评估DTW时打印）=====
    _onlineEvalCount++;
    final vecStd = _standardizeVector(vecRaw);

    final isNewBest = similarity > _onlineBestSimilarity + 1e-4;
    final shouldPrintPeriodic = (_onlineEvalCount % _onlineDebugPrintEveryEvals == 0);
    if (isNewBest || shouldPrintPeriodic) {
      if (isNewBest) _onlineBestSimilarity = similarity;
      final noseY = pose.landmarks[PoseLandmarkType.nose]?.y;
      final leftWristY = pose.landmarks[PoseLandmarkType.leftWrist]?.y;
      final rightWristY = pose.landmarks[PoseLandmarkType.rightWrist]?.y;
      final leftHipY = pose.landmarks[PoseLandmarkType.leftHip]?.y;
      final rightHipY = pose.landmarks[PoseLandmarkType.rightHip]?.y;
      String bodyHDebug = 'NA';
      if (noseY != null && leftHipY != null && rightHipY != null) {
        final hipCenterY = (leftHipY + rightHipY) / 2.0;
        bodyHDebug = (hipCenterY - noseY).abs().toStringAsFixed(3);
      }
      Log.d(
        'DTW[eval=$_onlineEvalCount] frame=$_frameCounter onlineStarted=$_onlineStarted '
        'bufLen=${_onlineBuffer.length} takeLen=$takeLen resizedLen=${resized.length} '
        'dist=${dist.toStringAsFixed(4)} avgCost=${avgCost.toStringAsFixed(6)} sim=${similarity.toStringAsFixed(2)} '
        'vecRaw=${_formatVec(vecRaw)} vecStd=${_formatVec(vecStd)} '
        'rawY(nose/lw/rw)=(${noseY?.toStringAsFixed(3) ?? 'NA'},${leftWristY?.toStringAsFixed(3) ?? 'NA'},${rightWristY?.toStringAsFixed(3) ?? 'NA'}) '
        'bodyH(px)=$bodyHDebug',
        tag: 'DTW',
      );
    }

    if (similarity >= passSimilarityThreshold) {
      final wristRelNow = _wristRelYUpFromPose(pose);
      if (wristRelNow == null) {
        _onlinePassStreak = 0;
        return null;
      }
      final leftWristRelYUpNow = wristRelNow.$1;
      final rightWristRelYUpNow = wristRelNow.$2;
      final wristsOk = _isPassWristPoseOk(leftWristRelYUpNow, rightWristRelYUpNow);

      if (wristsOk) {
        _onlinePassStreak++;
        if (_onlinePassStreak >= _onlinePassHoldFrames) {
          // 命中完成后清理缓存，避免重复触发
          _onlinePassStreak = 0;
          _onlineBuffer.clear();
          _onlineStarted = false;
          return DtwMatchResult(
            similarity: lastSimilarity!,
            passed: true,
            dtwDistance: dist,
          );
        }
      } else {
        // 相似度足够但手腕高度不足：重置连续命中
        _onlinePassStreak = 0;
      }
    } else {
      _onlinePassStreak = 0;
    }

    return null;
  }

  // 返回：当检测到结束时给出 match result；否则返回 null。
  DtwMatchResult? update(Pose pose) {
    if (_template == null) return null;

    final vec = extractFeatureVector(pose);
    if (vec == null) {
      // 特征提取失败，不参与录制
      return null;
    }
    final features = vec;

    if (!_recording) {
      if (_isStartPose(pose)) {
        _recording = true;
        _userSeq.clear();
        _endLowCount = 0;
        _frameCounter = 0;
        // 录入当前帧
        _userSeq.add(_standardizeVector(features));
      }
      return null;
    }

    // recording中：进行下采样采样
    if (_frameCounter % _frameSkip == 0) {
      if (_userSeq.length >= maxRecordFrames) {
        // 超长直接结束
        return _computeAndFinish();
      }
      _userSeq.add(_standardizeVector(features));
    }
    _frameCounter++;

    // 结束判断（双手落下）
    final wristRel = _wristRelYUpFromPose(pose);
    if (wristRel == null) return null;
    final leftWristRelYUp = wristRel.$1;
    final rightWristRelYUp = wristRel.$2;
    final lowNow = leftWristRelYUp < endWristRelYUp && rightWristRelYUp < endWristRelYUp;
    if (lowNow) {
      _endLowCount++;
    } else {
      _endLowCount = 0;
    }

    if (_endLowCount >= endHoldFrames && _userSeq.length >= minRecordFrames) {
      return _computeAndFinish();
    }

    return null;
  }

  List<List<double>> _resampleToTargetLen(List<List<double>> seq, int targetLen) {
    final inLen = seq.length;
    if (inLen == targetLen) return seq;
    if (inLen <= 1) {
      // 不足以插值：重复单点
      return List<List<double>>.generate(
        targetLen,
        (_) => List<double>.from(seq.first),
        growable: false,
      );
    }

    final out = <List<double>>[];
    for (int k = 0; k < targetLen; k++) {
      final t = k / (targetLen - 1); // 0..1
      final pos = t * (inLen - 1);
      final i0 = pos.floor();
      final i1 = math.min(inLen - 1, i0 + 1);
      final a = pos - i0;

      final row = List<double>.generate(_template!.featureDim, (d) {
        final v0 = seq[i0][d];
        final v1 = seq[i1][d];
        return v0 * (1.0 - a) + v1 * a;
      }, growable: false);

      out.add(row);
    }
    return out;
  }

  DtwMatchResult _computeAndFinish() {
    final template = _templateStd;
    final user = _userSeq;

    final dist = dtwDistance(
      user,
      template,
      window: 18,
      dimsToUse: _useFullBodyByTemplate ? null : _trajectoryDims,
    );

    // 使用“平均对齐成本”转成 0..100 相似度
    final avgCost = dist / (user.length + template.length);
    final similarity = 100.0 / (1.0 + avgCost / 40.0);
    final passed = similarity >= passSimilarityThreshold;

    resetRecording();
    return DtwMatchResult(
      similarity: similarity.clamp(0.0, 100.0),
      passed: passed,
      dtwDistance: dist,
    );
  }

  List<double>? extractFeatureVector(Pose pose) {
    if (_featureMode == DtwFeatureMode.keypoints6) {
      return _extractFeatureVectorKeypoints6(pose);
    }
    return _extractFeatureVectorFullBody(pose);
  }

  List<double>? _extractFeatureVectorFullBody(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    if (nose == null || lh == null || rh == null) return null;

    final noseXYUp = _pt(nose.x, 1 - nose.y);
    final lhXYUp = _pt(lh.x, 1 - lh.y);
    final rhXYUp = _pt(rh.x, 1 - rh.y);
    final hipCenter = _pt((lhXYUp.dx + rhXYUp.dx) / 2, (lhXYUp.dy + rhXYUp.dy) / 2);
    final bodyH = _dist(noseXYUp, hipCenter);
    if (bodyH < 1e-6) return null;

    final out = <double>[];
    for (final type in PoseLandmarkType.values) {
      final lm = pose.landmarks[type];
      if (lm == null) return null;
      final xRel = (lm.x - noseXYUp.dx) / bodyH;
      final yRel = ((1 - lm.y) - noseXYUp.dy) / bodyH;
      out.add(xRel);
      out.add(yRel);
    }
    return out;
  }

  List<double>? _extractFeatureVectorKeypoints6(Pose pose) {
    double? getY(PoseLandmarkType type) => pose.landmarks[type]?.y;
    double? getX(PoseLandmarkType type) => pose.landmarks[type]?.x;

    final noseX = getX(PoseLandmarkType.nose);
    final noseY = getY(PoseLandmarkType.nose);
    final lsX = getX(PoseLandmarkType.leftShoulder);
    final lsY = getY(PoseLandmarkType.leftShoulder);
    final rsX = getX(PoseLandmarkType.rightShoulder);
    final rsY = getY(PoseLandmarkType.rightShoulder);
    final leX = getX(PoseLandmarkType.leftElbow);
    final leY = getY(PoseLandmarkType.leftElbow);
    final reX = getX(PoseLandmarkType.rightElbow);
    final reY = getY(PoseLandmarkType.rightElbow);
    final lwX = getX(PoseLandmarkType.leftWrist);
    final lwY = getY(PoseLandmarkType.leftWrist);
    final rwX = getX(PoseLandmarkType.rightWrist);
    final rwY = getY(PoseLandmarkType.rightWrist);
    final lhX = getX(PoseLandmarkType.leftHip);
    final lhY = getY(PoseLandmarkType.leftHip);
    final rhX = getX(PoseLandmarkType.rightHip);
    final rhY = getY(PoseLandmarkType.rightHip);

    if ([noseX, noseY, lsX, lsY, rsX, rsY, leX, leY, reX, reY, lwX, lwY, rwX, rwY, lhX, lhY, rhX, rhY].any((v) => v == null)) {
      return null;
    }

    final noseXYUp = _pt(noseX!, 1 - noseY!);
    final lsXYUp = _pt(lsX!, 1 - lsY!);
    final rsXYUp = _pt(rsX!, 1 - rsY!);
    final leXYUp = _pt(leX!, 1 - leY!);
    final reXYUp = _pt(reX!, 1 - reY!);
    final lwXYUp = _pt(lwX!, 1 - lwY!);
    final rwXYUp = _pt(rwX!, 1 - rwY!);
    final lhXYUp = _pt(lhX!, 1 - lhY!);
    final rhXYUp = _pt(rhX!, 1 - rhY!);

    final hipCenter = _pt((lhXYUp.dx + rhXYUp.dx) / 2, (lhXYUp.dy + rhXYUp.dy) / 2);
    final bodyH = _dist(noseXYUp, hipCenter);
    if (bodyH < 1e-6) return null;

    final leftElbowAngle = _angle(lsXYUp, leXYUp, lwXYUp);
    final rightElbowAngle = _angle(rsXYUp, reXYUp, rwXYUp);
    final leftWristRelYUp = (lwXYUp.dy - noseXYUp.dy) / bodyH;
    final rightWristRelYUp = (rwXYUp.dy - noseXYUp.dy) / bodyH;
    final shoulderYDiff = (lsXYUp.dy - rsXYUp.dy).abs() / bodyH;
    final torsoCenterX = (hipCenter.dx - noseXYUp.dx).abs() / bodyH;

    return <double>[
      leftElbowAngle,
      rightElbowAngle,
      leftWristRelYUp,
      rightWristRelYUp,
      shoulderYDiff,
      torsoCenterX,
    ];
  }

  bool _isStartPose(Pose pose) {
    final wristRel = _wristRelYUpFromPose(pose);
    if (wristRel == null) return false;
    final leftWristRelYUp = wristRel.$1;
    final rightWristRelYUp = wristRel.$2;
    if (!_isStartWristPoseOk(leftWristRelYUp, rightWristRelYUp)) return false;

    // 手腕为主条件；肘部按动作类型做辅助（非对称动作不强行要求对侧肘也“抬高”）。
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final le = pose.landmarks[PoseLandmarkType.leftElbow];
    final re = pose.landmarks[PoseLandmarkType.rightElbow];

    if (nose == null || lh == null || rh == null || ls == null || rs == null || le == null || re == null) return false;

    final noseXYUp = _pt(nose.x, 1 - nose.y);
    final leXYUp = _pt(le.x, 1 - le.y);
    final reXYUp = _pt(re.x, 1 - re.y);
    final lsXYUp = _pt(ls.x, 1 - ls.y);
    final rsXYUp = _pt(rs.x, 1 - rs.y);
    final hipCenter = _pt((lh.x + rh.x) / 2, (1 - lh.y + 1 - rh.y) / 2);

    final bodyH = _dist(noseXYUp, hipCenter);
    if (bodyH < 1e-6) return false;

    final leftElbowRelYUp = (leXYUp.dy - lsXYUp.dy) / bodyH; // elbow 相对肩
    final rightElbowRelYUp = (reXYUp.dy - rsXYUp.dy) / bodyH;

    final elbowAuxOk = _isStartElbowAuxOk(leftElbowRelYUp, rightElbowRelYUp);
    return elbowAuxOk || _isStartWristPoseOk(leftWristRelYUp, rightWristRelYUp);
  }

  /// 起势时肘部相对肩的“抬高”辅助条件（y-up 越大越靠上），按动作选用单侧或跳过。
  bool _isStartElbowAuxOk(double leftElbowRelYUp, double rightElbowRelYUp) {
    switch (_actionType) {
      case '左右开弓-左':
        return leftElbowRelYUp > startElbowRelYUp;
      case '左右开弓-右':
        return rightElbowRelYUp > startElbowRelYUp;
      case '调理脾胃-左':
        return leftElbowRelYUp > startElbowRelYUp;
      case '调理脾胃-右':
        return rightElbowRelYUp > startElbowRelYUp;
      case '摇头摆尾-左':
      case '摇头摆尾-右':
        return true;
      default:
        return leftElbowRelYUp > startElbowRelYUp && rightElbowRelYUp > startElbowRelYUp;
    }
  }

  bool _isStartWristPoseOk(double leftWristRelYUp, double rightWristRelYUp) {
    switch (_actionType) {
      case '双手托天':
        return leftWristRelYUp >= _startWristRelYUpStep1 &&
            rightWristRelYUp >= _startWristRelYUpStep1;
      case '左右开弓-左':
        return leftWristRelYUp >= _startWristRelYUpStep2;
      case '左右开弓-右':
        return rightWristRelYUp >= _startWristRelYUpStep2;
      case '调理脾胃-左':
        return leftWristRelYUp >= _startWristRelYUpStep3;
      case '调理脾胃-右':
        return rightWristRelYUp >= _startWristRelYUpStep3;
      case '摇头摆尾-左':
      case '摇头摆尾-右':
        return true;
      default:
        return leftWristRelYUp >= _startWristRelYUpStep1 &&
            rightWristRelYUp >= _startWristRelYUpStep1;
    }
  }

  bool _isPassWristPoseOk(double leftWristRelYUp, double rightWristRelYUp) {
    switch (_actionType) {
      case '双手托天':
        return leftWristRelYUp >= _passWristRelYUpStep1 &&
            rightWristRelYUp >= _passWristRelYUpStep1;
      case '左右开弓-左':
        return leftWristRelYUp >= _passWristRelYUpStep2;
      case '左右开弓-右':
        return rightWristRelYUp >= _passWristRelYUpStep2;
      case '调理脾胃-左':
        return rightWristRelYUp >= _passWristRelYUpStep3;
      case '调理脾胃-右':
        return leftWristRelYUp >= _passWristRelYUpStep3;
      case '摇头摆尾-左':
      case '摇头摆尾-右':
        return true;
      default:
        return leftWristRelYUp >= passWristRelYUpMin &&
            rightWristRelYUp >= passWristRelYUpMin;
    }
  }

  (double, double)? _wristRelYUpFromPose(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    if (nose == null || lh == null || rh == null || lw == null || rw == null) return null;

    final noseXYUp = _pt(nose.x, 1 - nose.y);
    final hipCenter = _pt((lh.x + rh.x) / 2, (1 - lh.y + 1 - rh.y) / 2);
    final bodyH = _dist(noseXYUp, hipCenter);
    if (bodyH < 1e-6) return null;

    final lwYUp = 1 - lw.y;
    final rwYUp = 1 - rw.y;
    final leftWristRelYUp = (lwYUp - noseXYUp.dy) / bodyH;
    final rightWristRelYUp = (rwYUp - noseXYUp.dy) / bodyH;
    return (leftWristRelYUp, rightWristRelYUp);
  }

  List<double> _standardizeVector(List<double> v) {
    final t = _template!;
    if (v.length != t.featureDim) {
      Log.d(
        'DTW: feature dim mismatch mode=$_featureMode vecDim=${v.length} tplDim=${t.featureDim}',
        tag: 'DTW',
      );
      return List<double>.filled(t.featureDim, 0.0, growable: false);
    }
    return List<double>.generate(
      t.featureDim,
      (i) => (v[i] - t.mean[i]) / (t.std[i] == 0 ? 1.0 : t.std[i]),
      growable: false,
    );
  }

  String _formatVec(List<double> v) {
    return '[${v.map((e) => e.toStringAsFixed(3)).join(',')}]';
  }

  // 受限带宽 DTW：window 表示 i-j 允许的最大偏差
  static double dtwDistance(
    List<List<double>> a,
    List<List<double>> b, {
    int window = 20,
    List<int>? dimsToUse,
  }) {
    if (a.isEmpty || b.isEmpty) return double.infinity;

    final n = a.length;
    final m = b.length;

    final w = math.max(window, (n - m).abs()) + 2;

    // dp[j] = 当前行 i 对应到 j 的最小距离
    List<double> prev = List<double>.filled(m, double.infinity);
    List<double> curr = List<double>.filled(m, double.infinity);

    prev[0] = _vecDistSq(a[0], b[0], dimsToUse: dimsToUse);

    for (int i = 0; i < n; i++) {
      final jStart = math.max(0, i - w).toInt();
      final jEnd = math.min(m - 1, i + w).toInt();
      for (int j = jStart; j <= jEnd; j++) {
        final cost = _vecDistSq(a[i], b[j], dimsToUse: dimsToUse);
        if (i == 0 && j == 0) {
          curr[j] = cost;
          continue;
        }

        // bestPrev 取 min(dp[i-1][j-1], dp[i-1][j], dp[i][j-1]) 的简化写法：
        final diag = (i > 0 && j > 0) ? prev[j - 1] : double.infinity;
        final up = (i > 0) ? prev[j] : double.infinity;
        final left = (j > 0) ? curr[j - 1] : double.infinity;
        final minPrev = math.min(diag, math.min(up, left));

        curr[j] = cost + minPrev;
      }
      // 清空窗口外
      for (int j = 0; j < jStart; j++) {
        curr[j] = double.infinity;
      }
      for (int j = jEnd + 1; j < m; j++) {
        curr[j] = double.infinity;
      }

      prev = List<double>.from(curr);
      curr = List<double>.filled(m, double.infinity);
    }

    final end = prev[m - 1];
    return end.isInfinite ? double.infinity : end;
  }

  static double _vecDistSq(
    List<double> v1,
    List<double> v2, {
    List<int>? dimsToUse,
  }) {
    double s = 0;
    final len = math.min(v1.length, v2.length);
    if (dimsToUse == null) {
      for (int i = 0; i < len; i++) {
        final d = v1[i] - v2[i];
        s += d * d;
      }
    } else {
      for (final idx in dimsToUse) {
        if (idx < 0 || idx >= len) continue;
        final d = v1[idx] - v2[idx];
        s += d * d;
      }
    }
    return s;
  }

  // ---- 2D 小工具（不用 dart:ui 的 Offset，避免导入冲突）----
  static _Pt _pt(double x, double y) => _Pt(x, y);

  static double _dist(_Pt a, _Pt b) => math.sqrt(_distSq(a, b));

  static double _distSq(_Pt a, _Pt b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return dx * dx + dy * dy;
  }

  static double _angle(_Pt a, _Pt b, _Pt c) {
    // angle at b: a-b-c
    final v1x = a.dx - b.dx;
    final v1y = a.dy - b.dy;
    final v2x = c.dx - b.dx;
    final v2y = c.dy - b.dy;
    final n1 = math.sqrt(v1x * v1x + v1y * v1y);
    final n2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (n1 < 1e-6 || n2 < 1e-6) return 0.0;
    var cosAng = (v1x * v2x + v1y * v2y) / (n1 * n2);
    cosAng = cosAng.clamp(-1.0, 1.0);
    return math.acos(cosAng) * 180.0 / math.pi;
  }
}

class _Pt {
  final double dx;
  final double dy;
  const _Pt(this.dx, this.dy);
}

