import argparse
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--video", required=True)
    ap.add_argument("--step_fps", type=int, default=15)
    args = ap.parse_args()

    landmarker = load_landmarker()

    cap = cv2.VideoCapture(args.video)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    step = max(1, int(round(fps / args.step_fps)))
    raw_seq = []
    frame_idx = 0

    while True:
        ok, frame = cap.read()
        if not ok:
            break
        if frame_idx % step != 0:
            frame_idx += 1
            continue
        frame_idx += 1

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img = image_lib.Image(
            image_format=image_lib.ImageFormat.SRGB, data=rgb
        )
        res = landmarker.detect(img)
        if not res.pose_landmarks:
            continue
        f = features_from_pose_landmarks(res.pose_landmarks[0])
        if f is None:
            continue
        raw_seq.append(f)

    cap.release()
    if not raw_seq:
        raise RuntimeError("no features extracted")

    raw_np = np.asarray(raw_seq, dtype=float)
    print("extract_frames", len(raw_seq), "fps", fps, "step", step)
    print("raw_min", raw_np.min(axis=0).tolist())
    print("raw_max", raw_np.max(axis=0).tolist())

    # quick heuristics: detect frames where both wrists are above the threshold
    left_wrist_y_idx = LEFT_WRIST * 2 + 1
    right_wrist_y_idx = RIGHT_WRIST * 2 + 1
    wrists_above = (raw_np[:, left_wrist_y_idx] > 0.05) & (raw_np[:, right_wrist_y_idx] > 0.05)
    active = wrists_above
    print("active_frames_count", int(active.sum()), "active_ratio", float(active.mean()))

    # count partial matches
    print("left_wrist_above_frames", int((raw_np[:, left_wrist_y_idx] > 0.05).sum()))
    print("right_wrist_above_frames", int((raw_np[:, right_wrist_y_idx] > 0.05).sum()))


if __name__ == "__main__":
    main()

