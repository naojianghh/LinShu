// import 'package:dio/dio.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// import '../models/five_tone_track.dart';
//
// class FiveToneService {
//   FiveToneService({Dio? dio})
//     : _dio =
//           dio ??
//           Dio(
//             BaseOptions(
//               connectTimeout: const Duration(seconds: 8),
//               receiveTimeout: const Duration(seconds: 8),
//               sendTimeout: const Duration(seconds: 8),
//             ),
//           );
//
//   final Dio _dio;
//
//   String get _baseUrl => dotenv.env['APP_API_BASE_URL']?.trim() ?? '';
//
//   Future<List<FiveToneTrack>> fetchTracksByTone(String tone) async {
//     if (_baseUrl.isEmpty) {
//       throw Exception('APP_API_BASE_URL 未配置，请先配置后端地址');
//     }
//
//     try {
//       final response = await _dio.get(
//         '$_baseUrl/five-tone/tracks',
//         queryParameters: {'tone': tone},
//       );
//
//       final data = response.data;
//       final List<dynamic> list;
//
//       if (data is List) {
//         list = data;
//       } else if (data is Map<String, dynamic> && data['data'] is List) {
//         list = data['data'] as List<dynamic>;
//       } else {
//         throw Exception('接口返回格式不正确');
//       }
//
//       final tracks = list
//           .whereType<Map<String, dynamic>>()
//           .map(FiveToneTrack.fromJson)
//           .where((e) => e.audioUrl.isNotEmpty)
//           .toList();
//
//       if (tracks.isEmpty) {
//         throw Exception('暂无可播放曲目');
//       }
//
//       return tracks;
//     } on DioException catch (e) {
//       throw Exception('获取五音曲目失败: ${e.message ?? '网络请求失败'}');
//     }
//   }
// }
