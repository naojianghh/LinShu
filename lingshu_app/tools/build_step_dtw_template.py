import argparse
import json
import math
import urllib.request

import cv2
import numpy as np

from mediapipe.tasks.python.core.base_options import BaseOptions
from mediapipe.tasks.python.vision import PoseLandmarker, PoseLandmarkerOptions
from mediapipe.tasks.python.vision.core.vision_task_running_mode import (
    VisionTaskRunningMode,
)
from mediapipe.tasks.python.vision.core import image as image_lib


POSE_MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
    "pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task"
)

NOSE = 0
LEFT_WRIST = 15
RIGHT_WRIST = 16
LEFT_HIP = 23
RIGHT_HIP = 24


def dist(a, b) -> float:
    return float(math.dist(a, b))


def features_from_pose_landmarks(lms):
    def xy_up(p):
        return (p.x, 1.0 - p.y)

    nose = lms[NOSE]
    lh = lms[LEFT_HIP]
    rh = lms[RIGHT_HIP]
    nose_xy = xy_up(nose)
    lh_xy = xy_up(lh)
    rh_xy = xy_up(rh)
    hip_center = ((lh_xy[0] + rh_xy[0]) / 2.0, (lh_xy[1] + rh_xy[1]) / 2.0)
    body_h = dist(nose_xy, hip_center)
    if body_h < 1e-6:
        return None

    out = []
    for p in lms:
        x_up, y_up = xy_up(p)
        out.append((x_up - nose_xy[0]) / body_h)
        out.append((y_up - nose_xy[1]) / body_h)
    return out


def load_landmarker():
    model_bytes = urllib.request.urlopen(POSE_MODEL_URL).read()
    base_options = BaseOptions(model_asset_buffer=model_bytes)
    options = PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=VisionTaskRunningMode.IMAGE,
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_pose_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )
    return PoseLandmarker.create_from_options(options)


def resample_to_target(seq, target_len: int):
    in_len = len(seq)
    if in_len == target_len:
        return np.asarray(seq, dtype=float)
    if in_len <= 1:
        return np.asarray([list(seq[0])] * target_len, dtype=float)
    x_old = np.linspace(0, 1, in_len)
    x_new = np.linspace(0, 1, target_len)
    seq_np = np.asarray(seq, dtype=float)
    resized = np.vstack([np.interp(x_new, x_old, seq_np[:, d]) for d in range(seq_np.shape[1])]).T
    return resized


def extract_features(video_path: str, step: int, landmarker):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(f"cannot open video: {video_path}")

    raw_seq = []
    frame_ids = []
    frame_idx = 0

    while True:
        ok, frame = cap.read()
        if not ok:
            break
        if frame_idx % step != 0:
            frame_idx += 1
            continue
        cur_idx = frame_idx
        frame_idx += 1

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img = image_lib.Image(image_format=image_lib.ImageFormat.SRGB, data=rgb)
        res = landmarker.detect(img)
        if not res.pose_landmarks:
            continue
        f = features_from_pose_landmarks(res.pose_landmarks[0])
        if f is None:
            continue
        raw_seq.append(f)
        frame_ids.append(cur_idx)

    cap.release()
    return raw_seq, frame_ids


def pick_trim_indices(raw_np):
    left_wrist_y_idx = LEFT_WRIST * 2 + 1
    right_wrist_y_idx = RIGHT_WRIST * 2 + 1
    wrists_above = (raw_np[:, left_wrist_y_idx] > 0.05) & (raw_np[:, right_wrist_y_idx] > 0.05)
    active_idx = np.where(wrists_above)[0]
    if len(active_idx) == 0:
        return 0, len(raw_np) - 1
    start = int(active_idx[0])
    end = int(active_idx[-1])
    # 适度外扩，保留起势与回落上下文
    pad = max(2, int(0.08 * len(raw_np)))
    start = max(0, start - pad)
    end = min(len(raw_np) - 1, end + pad)
    if end <= start:
        return 0, len(raw_np) - 1
    return start, end


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--video", required=True, help="template source mp4")
    ap.add_argument("--out", required=True, help="output dtw template json")
    ap.add_argument("--step_fps", type=int, default=15)
    ap.add_argument("--target_len", type=int, default=40)
    ap.add_argument("--name", default="baduanjin_step1_dtw_template")
    args = ap.parse_args()

    landmarker = load_landmarker()

    cap = cv2.VideoCapture(args.video)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    cap.release()
    step = max(1, int(round(fps / args.step_fps)))

    raw_seq, frame_ids = extract_features(args.video, step=step, landmarker=landmarker)
    if not raw_seq:
        raise RuntimeError("no features extracted")

    raw_np = np.asarray(raw_seq, dtype=float)
    trim_s, trim_e = pick_trim_indices(raw_np)
    trimmed = raw_np[trim_s : trim_e + 1]
    resized = resample_to_target(trimmed.tolist(), args.target_len)

    mean = resized.mean(axis=0)
    std = resized.std(axis=0)
    std[std == 0] = 1.0

    out = {
        "name": args.name,
        "target_len": int(args.target_len),
        "feature_dim": int(resized.shape[1]),
        "trim": [int(frame_ids[trim_s]), int(frame_ids[trim_e])],
        "mean": mean.tolist(),
        "std": std.tolist(),
        "features": resized.tolist(),
    }

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))

    print("video", args.video)
    print("fps", fps, "step", step, "extract_frames", len(raw_seq))
    print("trim_local", [trim_s, trim_e], "trim_src_frames", out["trim"])
    print("target_len", out["target_len"], "feature_dim", out["feature_dim"])
    print("saved", args.out)


if __name__ == "__main__":
    main()

