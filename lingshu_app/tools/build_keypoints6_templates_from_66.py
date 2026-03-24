import argparse
import json
import math
from pathlib import Path


LEFT_SHOULDER = 11
RIGHT_SHOULDER = 12
LEFT_ELBOW = 13
RIGHT_ELBOW = 14
LEFT_WRIST = 15
RIGHT_WRIST = 16
LEFT_HIP = 23
RIGHT_HIP = 24


def _point(frame66, idx):
    return frame66[2 * idx], frame66[2 * idx + 1]


def _angle(a, b, c):
    # angle at b: a-b-c, in degrees
    v1x = a[0] - b[0]
    v1y = a[1] - b[1]
    v2x = c[0] - b[0]
    v2y = c[1] - b[1]
    n1 = math.sqrt(v1x * v1x + v1y * v1y)
    n2 = math.sqrt(v2x * v2x + v2y * v2y)
    if n1 < 1e-6 or n2 < 1e-6:
        return 0.0
    cos_ang = (v1x * v2x + v1y * v2y) / (n1 * n2)
    cos_ang = max(-1.0, min(1.0, cos_ang))
    return math.degrees(math.acos(cos_ang))


def frame66_to_keypoints6(frame66):
    # frame66 is relative to nose and normalized by body height.
    ls = _point(frame66, LEFT_SHOULDER)
    rs = _point(frame66, RIGHT_SHOULDER)
    le = _point(frame66, LEFT_ELBOW)
    re = _point(frame66, RIGHT_ELBOW)
    lw = _point(frame66, LEFT_WRIST)
    rw = _point(frame66, RIGHT_WRIST)
    lh = _point(frame66, LEFT_HIP)
    rh = _point(frame66, RIGHT_HIP)

    hip_center_x = (lh[0] + rh[0]) / 2.0

    left_elbow_angle = _angle(ls, le, lw)
    right_elbow_angle = _angle(rs, re, rw)
    left_wrist_rel_y_up = lw[1]
    right_wrist_rel_y_up = rw[1]
    shoulder_y_diff = abs(ls[1] - rs[1])
    torso_center_x = abs(hip_center_x)

    return [
        left_elbow_angle,
        right_elbow_angle,
        left_wrist_rel_y_up,
        right_wrist_rel_y_up,
        shoulder_y_diff,
        torso_center_x,
    ]


def mean_std(features):
    dim = len(features[0])
    n = len(features)
    mean = [0.0] * dim
    for f in features:
        for i, v in enumerate(f):
            mean[i] += v
    mean = [v / n for v in mean]

    var = [0.0] * dim
    for f in features:
        for i, v in enumerate(f):
            d = v - mean[i]
            var[i] += d * d
    std = [math.sqrt(v / n) for v in var]
    std = [s if s > 1e-8 else 1.0 for s in std]
    return mean, std


def convert_file(src_path, out_path):
    data = json.loads(src_path.read_text(encoding="utf-8"))
    if data.get("feature_dim") != 66:
        raise ValueError(f"{src_path.name} feature_dim != 66")

    src_features = data.get("features", [])
    if not src_features:
        raise ValueError(f"{src_path.name} has empty features")

    out_features = [frame66_to_keypoints6(f) for f in src_features]
    out_mean, out_std = mean_std(out_features)

    out_data = {
        "name": f"{data.get('name', src_path.stem)}_keypoints6",
        "target_len": data.get("target_len", len(out_features)),
        "feature_dim": 6,
        "trim": data.get("trim", [0, len(out_features) - 1]),
        "mean": out_mean,
        "std": out_std,
        "features": out_features,
        "source_template": src_path.name,
        "source_feature_dim": 66,
    }
    out_path.write_text(json.dumps(out_data, ensure_ascii=False), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Convert DTW 66D templates to keypoints6 templates.")
    parser.add_argument("--template-dir", required=True, help="Directory of original 66D templates.")
    parser.add_argument("--suffix", default="_kp6", help="Suffix inserted before .json for new files.")
    args = parser.parse_args()

    tpl_dir = Path(args.template_dir)
    if not tpl_dir.exists():
        raise FileNotFoundError(f"Template dir not found: {tpl_dir}")

    src_files = sorted(p for p in tpl_dir.glob("*_dtw_template.json"))
    if not src_files:
        raise RuntimeError(f"No *_dtw_template.json found in {tpl_dir}")

    converted = []
    for src in src_files:
        out = src.with_name(f"{src.stem}{args.suffix}.json")
        convert_file(src, out)
        converted.append(out.name)

    print("Converted templates:")
    for name in converted:
        print(f" - {name}")


if __name__ == "__main__":
    main()
