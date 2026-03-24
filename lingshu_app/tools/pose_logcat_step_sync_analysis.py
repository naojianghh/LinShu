import argparse
import json
import math
import re
from collections import defaultdict


POINTS = ["nose", "leftWrist", "rightWrist", "leftElbow", "rightElbow"]


def parse_logcat(path: str):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    msgs = data.get("logcatMessages", [])

    pat = re.compile(
        r"name:\s*(\w+),\s*原始点位:\s*\(([^,]+),([^\)]+)\)\s*转换后:\s*\(([^,]+),([^\)]+)\)"
    )

    rows = []
    for m in msgs:
        header = m.get("header", {})
        ts = header.get("timestamp", {})
        sec = ts.get("seconds")
        nanos = ts.get("nanos")
        if sec is None:
            continue
        message = m.get("message", "")
        if "PoseRender2" not in message or "绘制点位" not in message:
            continue
        mm = pat.search(message)
        if not mm:
            continue
        name = mm.group(1)
        if name not in POINTS:
            continue
        # use transformed y (group 5) and transformed x (group 4)
        x = float(mm.group(4))
        y = float(mm.group(5))
        t = float(sec) + float(nanos) / 1e9
        rows.append((t, name, x, y))

    rows.sort(key=lambda r: r[0])
    ser = defaultdict(list)
    for t, name, x, y in rows:
        ser[name].append((t, x, y))
    return ser


def nearest(ser_list, t):
    # ser_list: [(t,x,y)...] sorted by t
    return min(ser_list, key=lambda r: abs(r[0] - t))


def find_y_min_time(ser_list):
    # y smaller => higher on screen due to conversion logic
    y_min = min(ser_list, key=lambda r: r[2])[2]
    t = min(ser_list, key=lambda r: abs(r[2] - y_min))[0]
    _, x, _ = nearest(ser_list, t)
    return t, x, y_min


def format_frame(name, nose, lw, rw, le, re):
    # y smaller => higher
    def dy(a, b):
        return a - b

    return (
        f"{name}: "
        f"nose_y={nose[2]:.1f}, "
        f"Lw_y={lw[2]:.1f}(nose-dy={dy(nose[2], lw[2]):.1f}), "
        f"Rw_y={rw[2]:.1f}(nose-dy={dy(nose[2], rw[2]):.1f}), "
        f"Le_y={le[2]:.1f}(nose-dy={dy(nose[2], le[2]):.1f}), "
        f"Re_y={re[2]:.1f}(nose-dy={dy(nose[2], re[2]):.1f})"
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", required=True)
    ap.add_argument("--topDtw", type=int, default=8)
    args = ap.parse_args()

    ser = parse_logcat(args.log)

    for p in POINTS:
        print(p, "count", len(ser.get(p, [])))

    nose = ser["nose"]
    lw = ser["leftWrist"]
    rw = ser["rightWrist"]
    le = ser["leftElbow"]
    reL = ser["rightElbow"]

    # peaks (minimum y)
    tlw, _, ylw = find_y_min_time(lw)
    trw, _, yrw = find_y_min_time(rw)
    tle, _, yle = find_y_min_time(le)
    tre, _, yre = find_y_min_time(reL)

    print("\n=== Peaks (min y) ===")
    print(f"leftWrist peak: t={tlw:.3f}, y={ylw:.1f}")
    print(f"rightWrist peak: t={trw:.3f}, y={yrw:.1f}")
    print(f"leftElbow peak: t={tle:.3f}, y={yle:.1f}")
    print(f"rightElbow peak: t={tre:.3f}, y={yre:.1f}")

    print("\n=== Sync frames ===")
    for label, t0 in [
        ("T_leftWristPeak", tlw),
        ("T_rightWristPeak", trw),
        ("T_leftElbowPeak", tle),
        ("T_rightElbowPeak", tre),
    ]:
        nf = nearest(nose, t0)
        lwf = nearest(lw, t0)
        rwf = nearest(rw, t0)
        lef = nearest(le, t0)
        ref = nearest(reL, t0)
        print(format_frame(label, nf, lwf, rwf, lef, ref))

    # crossing: y < nose_y means "above nose"
    # find first time both wrists above nose
    def is_above(pt, nose_pt):
        return pt[2] < nose_pt[2]

    # build by iterating timestamps common-ish: use wrist timestamps as driver
    t_start = None
    t_elbow = None
    t_all = None
    for t_w, _, _ in lw:
        nose_pt = nearest(nose, t_w)
        lw_pt = nearest(lw, t_w)
        rw_pt = nearest(rw, t_w)
        le_pt = nearest(le, t_w)
        re_pt = nearest(reL, t_w)
        wrists_ok = is_above(lw_pt, nose_pt) and is_above(rw_pt, nose_pt)
        elbows_ok = is_above(le_pt, nose_pt) and is_above(re_pt, nose_pt)
        if t_start is None and wrists_ok:
            t_start = t_w
        if t_elbow is None and elbows_ok:
            t_elbow = t_w
        if t_all is None and wrists_ok and elbows_ok:
            t_all = t_w
            break

    print("\n=== First times above nose ===")
    print(f"first_both_wrists_above_nose: {t_start}")
    print(f"first_both_elbows_above_nose: {t_elbow}")
    print(f"first_both_wrists_and_elbows_above_nose: {t_all}")

    if t_start is not None:
        nf = nearest(nose, t_start)
        lwf = nearest(lw, t_start)
        rwf = nearest(rw, t_start)
        lef = nearest(le, t_start)
        ref = nearest(reL, t_start)
        print("\nFrame @ first both wrists above nose:")
        print(format_frame("T_bothWristsAboveNose", nf, lwf, rwf, lef, ref))

    if t_elbow is not None:
        nf = nearest(nose, t_elbow)
        lwf = nearest(lw, t_elbow)
        rwf = nearest(rw, t_elbow)
        lef = nearest(le, t_elbow)
        ref = nearest(reL, t_elbow)
        print("\nFrame @ first both elbows above nose:")
        print(format_frame("T_bothElbowsAboveNose", nf, lwf, rwf, lef, ref))

    # ---- DTW correlation (sim/acc) ----
    # Parse DTW evaluation logs in the same logcat json for stronger conclusion.
    with open(args.log, "r", encoding="utf-8") as f:
        data = json.load(f)
    msgs = data.get("logcatMessages", [])

    dtw_rows = []
    # Examples seen in app logs:
    # 1) "DTW: ready=true completed=false acc=4.329..."
    # 2) "DTW[eval=...] ... sim=16.23 vecRaw=[...]"
    rx_acc = re.compile(r"\bacc=([0-9eE\+\-\.]+)")
    rx_sim = re.compile(r"\bsim=([0-9eE\+\-\.]+)")
    for m in msgs:
        header = m.get("header", {})
        ts = header.get("timestamp", {})
        sec = ts.get("seconds")
        nanos = ts.get("nanos")
        if sec is None:
            continue
        message = m.get("message", "")
        if "DTW" not in message:
            continue
        # gate: only keep dtw matcher lines
        if "DTW:" not in message and "DTW[" not in message:
            continue
        sim = None
        mm = rx_sim.search(message)
        if mm:
            sim = float(mm.group(1))
        else:
            mm = rx_acc.search(message)
            if mm:
                sim = float(mm.group(1))
        if sim is None:
            continue
        t = float(sec) + float(nanos) / 1e9
        dtw_rows.append((t, sim, message))

    dtw_rows.sort(key=lambda r: r[1], reverse=True)
    print("\n=== DTW top similarities ===")
    def is_above(pt, nose_pt):
        # smaller y => higher
        return pt[2] < nose_pt[2]

    def best_near(target_t: float, window_s: float = 0.55):
        # return (best_sim, best_t, best_msg)
        cand = [row for row in dtw_rows if abs(row[0] - target_t) <= window_s]
        if not cand:
            return None
        # 如果同一时间窗里存在 vecRaw，优先选择包含 vecRaw 的日志
        cand_vec = [row for row in cand if "vecRaw=" in row[2]]
        if cand_vec:
            cand = cand_vec
        cand.sort(key=lambda r: r[1], reverse=True)
        return cand[0][1], cand[0][0], cand[0][2]

    def to_safe_text(s: str) -> str:
        # console encoding maybe gbk, keep output ascii only
        s = s.replace("\n", " ")
        return s.encode("ascii", "ignore").decode("ascii")

    rx_vecraw = re.compile(r"vecRaw=\[([^\]]+)\]")

    print("\n=== DTW near key pose moments ===")
    key_moments = [
        ("first_both_wrists_above_nose", t_start),
        ("first_both_elbows_above_nose", t_elbow),
        ("leftWrist_peak", tlw),
        ("rightWrist_peak", trw),
        ("leftElbow_peak", tle),
        ("rightElbow_peak", tre),
    ]
    for name, kt in key_moments:
        if kt is None:
            continue
        best = best_near(kt, window_s=0.6)
        if best is None:
            print(f"{name}: no DTW eval found in +-0.6s window around t={kt:.3f}")
            continue
        sim_best, t_best, msg_best = best
        nose_pt = nearest(nose, t_best)
        lw_pt = nearest(lw, t_best)
        rw_pt = nearest(rw, t_best)
        le_pt = nearest(le, t_best)
        re_pt = nearest(reL, t_best)
        wrists_ok = is_above(lw_pt, nose_pt) and is_above(rw_pt, nose_pt)
        elbows_ok = is_above(le_pt, nose_pt) and is_above(re_pt, nose_pt)
        lw_above = nose_pt[2] - lw_pt[2]
        rw_above = nose_pt[2] - rw_pt[2]
        le_above = nose_pt[2] - le_pt[2]
        re_above = nose_pt[2] - re_pt[2]
        short = to_safe_text(msg_best)[:140]
        vec = None
        mm_vec = rx_vecraw.search(msg_best)
        if mm_vec:
            vec_txt = mm_vec.group(1).strip()
            # expected: "a,b,c,d,e,f" (numbers)
            parts = [p.strip() for p in vec_txt.split(",") if p.strip() != ""]
            try:
                vec = [float(p) for p in parts]
            except Exception:
                vec = None
        le_ang = vec[0] if vec and len(vec) > 0 else None
        re_ang = vec[1] if vec and len(vec) > 1 else None
        le_ang_txt = f"{le_ang:.1f}" if le_ang is not None else "NA"
        re_ang_txt = f"{re_ang:.1f}" if re_ang is not None else "NA"
        print(
            f"{name}: bestSim={sim_best:.2f} at t={t_best:.3f} "
            f"wristsAbove={wrists_ok} elbowsAbove={elbows_ok} "
            f"aboveNose(dy): Lw={lw_above:.1f} Rw={rw_above:.1f} Le={le_above:.1f} Re={re_above:.1f} "
            f"elbowAngDeg: Le={le_ang_txt} Re={re_ang_txt} "
            f"msg='{short}...'"
        )

    for t, sim, msg in dtw_rows[: args.topDtw]:
        # get nearest pose frame landmarks
        nose_pt = nearest(nose, t)
        lw_pt = nearest(lw, t)
        rw_pt = nearest(rw, t)
        le_pt = nearest(le, t)
        re_pt = nearest(reL, t)
        # Convert tuples: (t,x,y) -> (t,x,y) already
        wrists_ok = is_above(lw_pt, nose_pt) and is_above(rw_pt, nose_pt)
        elbows_ok = is_above(le_pt, nose_pt) and is_above(re_pt, nose_pt)
        # distance to nose (how far above)
        lw_above = nose_pt[2] - lw_pt[2]
        rw_above = nose_pt[2] - rw_pt[2]
        le_above = nose_pt[2] - le_pt[2]
        re_above = nose_pt[2] - re_pt[2]
        short = to_safe_text(msg)[:160]
        print(
            f"t={t:.3f} sim={sim:.2f} "
            f"wristsAbove={wrists_ok} elbowsAbove={elbows_ok} "
            f"aboveNose(dy): Lw={lw_above:.1f} Rw={rw_above:.1f} Le={le_above:.1f} Re={re_above:.1f} "
            f"msg='{short}...'"
        )


if __name__ == "__main__":
    main()

