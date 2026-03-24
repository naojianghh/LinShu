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
        # convert from MLKit/media pipe: y down => y up
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


def vec_dist_sq(a, b, dims_to_use=None) -> float:
    a = np.asarray(a)
    b = np.asarray(b)
    d = a - b
    if dims_to_use is None:
        return float(np.sum(d * d))
    idx = list(dims_to_use)
    return float(np.sum((d[idx] * d[idx])))


def dtw_distance(a, b, window=18, dims_to_use=None) -> float:
    n = len(a)
    m = len(b)
    if n == 0 or m == 0:
        return float("inf")

    w = max(window, abs(n - m)) + 2
    prev = [float("inf")] * m
    curr = [float("inf")] * m
    prev[0] = vec_dist_sq(a[0], b[0], dims_to_use=dims_to_use)

    for i in range(n):
        j_start = max(0, i - w)
        j_end = min(m - 1, i + w)
        for j in range(j_start, j_end + 1):
            cost = vec_dist_sq(a[i], b[j], dims_to_use=dims_to_use)
            if i == 0 and j == 0:
                curr[j] = cost
                continue
            diag = prev[j - 1] if (i > 0 and j > 0) else float("inf")
            up = prev[j] if (i > 0) else float("inf")
            left = curr[j - 1] if (j > 0) else float("inf")
            min_prev = min(diag, up, left)
            curr[j] = cost + min_prev

        # clear window out of range
        for j in range(0, j_start):
            curr[j] = float("inf")
        for j in range(j_end + 1, m):
            curr[j] = float("inf")

        prev = list(curr)
        curr = [float("inf")] * m

    return prev[m - 1]


def resample_to_target(seq, target_len: int):
    in_len = len(seq)
    if in_len == target_len:
        return seq
    if in_len <= 1:
        return [list(seq[0])] * target_len
    x_old = np.linspace(0, 1, in_len)
    x_new = np.linspace(0, 1, target_len)
    seq_np = np.asarray(seq, dtype=float)
    resized = np.vstack([np.interp(x_new, x_old, seq_np[:, d]) for d in range(seq_np.shape[1])]).T
    return resized


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


def extract_features(video_path: str, step: int, landmarker):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError("cannot open video")

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
        img = image_lib.Image(image_format=image_lib.ImageFormat.SRGB, data=rgb)
        res = landmarker.detect(img)
        if not res.pose_landmarks:
            continue
        lms = res.pose_landmarks[0]
        f = features_from_pose_landmarks(lms)
        if f is None:
            continue
        raw_seq.append(f)

    cap.release()
    return raw_seq


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--template", required=True, help="path to dtw template json")
    ap.add_argument("--video", required=True, help="path to user mp4")
    ap.add_argument("--step_fps", type=int, default=15, help="target sampling fps")
    args = ap.parse_args()

    tpl = json.load(open(args.template, "r", encoding="utf-8"))
    mean = np.array(tpl["mean"], dtype=float)
    std = np.array(tpl["std"], dtype=float)
    std[std == 0] = 1.0
    T_std = (np.array(tpl["features"], dtype=float) - mean) / std
    target_len = int(tpl["target_len"])

    landmarker = load_landmarker()

    cap = cv2.VideoCapture(args.video)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    cap.release()
    step = max(1, int(round(fps / args.step_fps)))

    raw_seq = extract_features(args.video, step=step, landmarker=landmarker)
    if not raw_seq:
        raise RuntimeError("no features extracted")

    raw_np = np.asarray(raw_seq, dtype=float)
    seq_std = (raw_np - mean) / std

    print("extract_frames", len(raw_seq), "fps", fps, "step", step)
    print("raw_min", raw_np.min(axis=0).tolist())
    print("raw_max", raw_np.max(axis=0).tolist())

    # simple online evaluation approximating dtw_pose_matcher gating:
    # start when both wrists_rel_y_up >= 0.05
    start_wrist = 0.05
    left_wrist_y_idx = LEFT_WRIST * 2 + 1
    right_wrist_y_idx = RIGHT_WRIST * 2 + 1

    online_started = False
    buffer = []
    frame_counter = 0
    min_buffer_len = 25
    eval_every = 3
    max_buffer_len = 120

    best_similarity = -1.0
    best_i = None
    best_dist = None

    pass_threshold = 80.0

    for i in range(len(raw_seq)):
        f_raw = raw_np[i]

        if not online_started:
            if not (
                f_raw[left_wrist_y_idx] >= start_wrist
                and f_raw[right_wrist_y_idx] >= start_wrist
            ):
                continue
            online_started = True
            buffer = []
            frame_counter = 0

        buffer.append(seq_std[i].tolist())
        if len(buffer) > max_buffer_len:
            buffer = buffer[-max_buffer_len:]

        frame_counter += 1
        if len(buffer) < min_buffer_len:
            continue
        if frame_counter % eval_every != 0:
            continue

        take_len = min(len(buffer), max_buffer_len)
        window_seq = buffer[-take_len:]
        resized = resample_to_target(window_seq, target_len)

        dist_val = dtw_distance(resized, T_std.tolist(), window=18, dims_to_use=None)
        avg_cost = dist_val / (len(resized) + len(T_std))
        similarity = 100.0 / (1.0 + avg_cost / 40.0)

        if similarity > best_similarity:
            best_similarity = similarity
            best_i = i
            best_dist = dist_val

        # optional: stop if passes
        if similarity >= pass_threshold:
            # still keep scanning to find the max
            pass

    print("best_similarity", best_similarity, "best_frame_i", best_i, "best_dtwDistance", best_dist)

    # also compute whole-seq DTW after resampling entire seq (baseline)
    resized_full = resample_to_target(seq_std.tolist(), target_len)
    dist_full = dtw_distance(resized_full, T_std.tolist(), window=18, dims_to_use=None)
    avg_cost_full = dist_full / (len(resized_full) + len(T_std))
    sim_full = 100.0 / (1.0 + avg_cost_full / 40.0)
    print("full_seq_similarity", sim_full, "dist_full", dist_full)


if __name__ == "__main__":
    main()

