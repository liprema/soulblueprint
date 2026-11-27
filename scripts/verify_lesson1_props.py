#!/usr/bin/env python3
"""
Strict Sony Director 10/10 glTF 2.0 Binary Verifier for Chapter 1 Track L1-B Props:
1. mega_skyscraper_a.glb
2. mega_skyscraper_b.glb
3. mega_family_house.glb
4. prop_birthday_table.glb
5. prop_city_car.glb
6. mega_lighthouse.glb
"""
import json
import math
import os
import struct
import sys
from collections import defaultdict, deque

PROPS_DIR = "/home/antigravity/liprema/soulblueprint/assets/models/lesson1/props"

TARGETS = [
    ("mega_skyscraper_a.glb",   (900, 3000), (46.0, 52.0), (14.0, 18.0)),
    ("mega_skyscraper_b.glb",   (900, 3000), (36.0, 42.0), (12.0, 16.0)),
    ("mega_family_house.glb",   (800, 2500), (9.5, 12.0),  (10.0, 13.0)),
    ("prop_birthday_table.glb", (2000, 5000), (1.1, 1.4),   (2.0, 2.6)),
    ("prop_city_car.glb",       (900, 2500), (1.3, 1.65),  (1.6, 2.0)),
    ("mega_lighthouse.glb",     (1500, 3500), (20.0, 23.0), (5.5, 7.5)),
]

COMP_TYPES = {
    5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
    5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4),
}
TYPE_COUNTS = {
    "SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16,
}


def read_accessor(gltf, bin_data, acc_idx):
    acc = gltf["accessors"][acc_idx]
    bv = gltf["bufferViews"][acc["bufferView"]]
    fmt_char, comp_size = COMP_TYPES[acc["componentType"]]
    num_comp = TYPE_COUNTS[acc["type"]]
    count = acc["count"]
    byte_offset = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride", comp_size * num_comp)
    elem_fmt = "<" + fmt_char * num_comp
    elem_size = comp_size * num_comp
    return [
        struct.unpack(elem_fmt, bin_data[byte_offset + i * stride : byte_offset + i * stride + elem_size])
        for i in range(count)
    ]


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def vlen(a):
    return math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])


def verify_glb(path):
    with open(path, "rb") as f:
        data = f.read()

    magic, version, length = struct.unpack("<4sII", data[:12])
    assert magic == b"glTF" and version == 2 and length == len(data), "Invalid GLB header"

    offset = 12
    gltf = None
    bin_chunk = b""
    while offset < len(data):
        clen, ctype = struct.unpack("<I4s", data[offset : offset + 8])
        offset += 8
        cbytes = data[offset : offset + clen]
        offset += clen
        if ctype == b"JSON":
            gltf = json.loads(cbytes.decode("utf-8"))
        elif ctype == b"BIN\x00":
            bin_chunk = cbytes
    assert gltf is not None, "Missing JSON chunk"

    mats = gltf.get("materials", [])
    ds = sum(1 for m in mats if m.get("doubleSided", False))
    non_opaque = sum(1 for m in mats if m.get("alphaMode", "OPAQUE") != "OPAQUE")
    mat_names = [m.get("name", "") for m in mats]

    missing_attrs = []
    nan_inf = 0
    bad_normals = 0
    degen_tris = 0
    flipped_tris = 0
    total_tris = 0
    f_vn = 0
    sm_h = 0
    cr_h = 0
    curved_edges = 0
    curved_smooth = 0

    min_x = min_y = min_z = float("inf")
    max_x = max_y = max_z = float("-inf")

    global_pos_to_wid = {}
    global_w_coords = []
    global_edge_counts = defaultdict(int)
    global_adj = defaultdict(list)
    global_tris = []

    for mi, mesh in enumerate(gltf.get("meshes", [])):
        for pi, prim in enumerate(mesh.get("primitives", [])):
            attrs = prim.get("attributes", {})
            for req in ("POSITION", "NORMAL", "TEXCOORD_0"):
                if req not in attrs:
                    missing_attrs.append(f"m{mi}.p{pi}:{req}")
            if missing_attrs:
                continue

            positions = read_accessor(gltf, bin_chunk, attrs["POSITION"])
            normals = read_accessor(gltf, bin_chunk, attrs["NORMAL"])
            uvs = read_accessor(gltf, bin_chunk, attrs["TEXCOORD_0"])

            for arr in (positions, normals, uvs):
                for tup in arr:
                    for v in tup:
                        if math.isnan(v) or math.isinf(v):
                            nan_inf += 1

            for (x, y, z) in positions:
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y
                if z < min_z: min_z = z
                if z > max_z: max_z = z

            for n in normals:
                nl = vlen(n)
                if nl < 0.99 or nl > 1.01:
                    bad_normals += 1

            indices = (
                [t[0] for t in read_accessor(gltf, bin_chunk, prim["indices"])]
                if "indices" in prim else list(range(len(positions)))
            )

            vert_to_wid = []
            for p in positions:
                key = (round(p[0], 4), round(p[1], 4), round(p[2], 4))
                if key not in global_pos_to_wid:
                    global_pos_to_wid[key] = len(global_w_coords)
                    global_w_coords.append(p)
                vert_to_wid.append(global_pos_to_wid[key])

            edge_faces = defaultdict(list)
            for t in range(0, len(indices), 3):
                i0, i1, i2 = indices[t], indices[t+1], indices[t+2]
                p0, p1, p2 = positions[i0], positions[i1], positions[i2]
                fn = cross(sub(p1, p0), sub(p2, p0))
                fl = vlen(fn)
                area = 0.5 * fl
                if area < 1e-8:
                    degen_tris += 1
                else:
                    fn_u = (fn[0]/fl, fn[1]/fl, fn[2]/fl)
                    avg_vn = (
                        normals[i0][0] + normals[i1][0] + normals[i2][0],
                        normals[i0][1] + normals[i1][1] + normals[i2][1],
                        normals[i0][2] + normals[i1][2] + normals[i2][2],
                    )
                    if dot(fn, avg_vn) < 0.0:
                        flipped_tris += 1
                    for vi in (i0, i1, i2):
                        if dot(normals[vi], fn_u) <= 0.0:
                            f_vn += 1

                    w = [vert_to_wid[i0], vert_to_wid[i1], vert_to_wid[i2]]
                    ii = [i0, i1, i2]
                    for a_i, b_i in ((0, 1), (1, 2), (2, 0)):
                        wa, wb = w[a_i], w[b_i]
                        ek = (wa, wb) if wa < wb else (wb, wa)
                        edge_faces[ek].append((fn_u, normals[ii[a_i]], normals[ii[b_i]], wa < wb))

                w0, w1, w2 = vert_to_wid[i0], vert_to_wid[i1], vert_to_wid[i2]
                global_tris.append((w0, w1, w2))
                for (a, b) in ((w0, w1), (w1, w2), (w2, w0)):
                    ek = (a, b) if a < b else (b, a)
                    global_edge_counts[ek] += 1
                    global_adj[a].append(b)
                    global_adj[b].append(a)
                total_tris += 1

            for ek, flist in edge_faces.items():
                if len(flist) != 2:
                    continue
                fn1, n1a, n1b, o1 = flist[0]
                fn2, n2a, n2b, o2 = flist[1]
                ang = math.degrees(math.acos(max(-1.0, min(1.0, dot(fn1, fn2)))))
                na1, nb1 = (n1a, n1b) if o1 else (n1b, n1a)
                na2, nb2 = (n2a, n2b) if o2 else (n2b, n2a)
                is_smoothed = (dot(na1, na2) > 0.99 and dot(nb1, nb2) > 0.99)
                if 1.0 < ang <= 50.0:
                    curved_edges += 1
                    if is_smoothed:
                        curved_smooth += 1
                elif ang >= 70.0:
                    if is_smoothed:
                        sm_h += 1
                    else:
                        cr_h += 1

    open_edges = sum(1 for cnt in global_edge_counts.values() if cnt == 1)

    # Shell identification (disconnected triangle clusters)
    visited = set()
    vert_shell = {}
    all_shell_aabbs = []
    shell_id = 0
    for wid in range(len(global_w_coords)):
        if wid in visited or wid not in global_adj:
            continue
        q = deque([wid])
        visited.add(wid)
        xs, ys, zs = [], [], []
        while q:
            cur = q.popleft()
            vert_shell[cur] = shell_id
            c = global_w_coords[cur]
            xs.append(c[0]); ys.append(c[1]); zs.append(c[2])
            for nxt in global_adj[cur]:
                if nxt not in visited:
                    visited.add(nxt)
                    q.append(nxt)
        all_shell_aabbs.append((min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
        shell_id += 1

    shell_vols = [0.0] * shell_id
    for (w0, w1, w2) in global_tris:
        sid = vert_shell[w0]
        p0, p1, p2 = global_w_coords[w0], global_w_coords[w1], global_w_coords[w2]
        shell_vols[sid] += dot(p0, cross(p1, p2)) / 6.0
    neg_vol = sum(1 for v in shell_vols if v <= 0.0)

    # 3D Connectivity & Grounding check:
    # AABB overlap graph: two shells connected if their AABBs intersect with tolerance 0.03m (30mm)
    n_shells = len(all_shell_aabbs)
    grounded = [False] * n_shells
    q = deque()
    # In glTF coords: Y is UP! (y_min is index 2 in our tuple: (min_x, max_x, min_y, max_y, min_z, max_z))
    for i, bb in enumerate(all_shell_aabbs):
        if bb[2] <= 0.008:
            grounded[i] = True
            q.append(i)

    tol = 0.035 # 35mm overlap tolerance
    shell_adj = defaultdict(list)
    for i in range(n_shells):
        a = all_shell_aabbs[i]
        for j in range(i + 1, n_shells):
            b = all_shell_aabbs[j]
            if (a[0] <= b[1] + tol and a[1] + tol >= b[0] and
                a[2] <= b[3] + tol and a[3] + tol >= b[2] and
                a[4] <= b[5] + tol and a[5] + tol >= b[4]):
                shell_adj[i].append(j)
                shell_adj[j].append(i)

    while q:
        cur = q.popleft()
        for nxt in shell_adj[cur]:
            if not grounded[nxt]:
                grounded[nxt] = True
                q.append(nxt)

    floating = sum(1 for g in grounded if not g)

    # Calculate number of connected components in the 3D overlap graph
    comp_visited = set()
    num_comps_3d = 0
    for i in range(n_shells):
        if i not in comp_visited:
            num_comps_3d += 1
            cq = deque([i])
            comp_visited.add(i)
            while cq:
                c_idx = cq.popleft()
                for n_idx in shell_adj[c_idx]:
                    if n_idx not in comp_visited:
                        comp_visited.add(n_idx)
                        cq.append(n_idx)

    return {
        "file": os.path.basename(path),
        "kb": round(len(data) / 1024.0, 1),
        "tris": total_tris,
        "W": max_x - min_x,
        "H": max_y - min_y, # In glTF, Y is UP!
        "D": max_z - min_z,
        "Y_min": min_y,
        "nan": nan_inf,
        "bad_n": bad_normals,
        "degen": degen_tris,
        "open": open_edges,
        "neg_vol": neg_vol,
        "flipped": flipped_tris,
        "f_vn": f_vn,
        "sm_h": sm_h,
        "cr_h": cr_h,
        "float": floating,
        "comps_3d": num_comps_3d,
        "ds": ds,
        "non_op": non_opaque,
        "missing": len(missing_attrs),
        "curved_smooth_pct": 100.0 * curved_smooth / max(1, curved_edges),
    }


def main():
    hdr = (
        f"{'File':25s} | {'KB':5s} | {'Tris':5s} | {'W x H x D (m)':18s} | {'Y_min':7s} | "
        f"{'Opn':3s} | {'Neg':3s} | {'Flp':3s} | {'F_VN':4s} | {'SM_H':4s} | {'C3D':3s} | "
        f"{'Flt':3s} | {'DS':2s} | {'OK'}"
    )
    print("================================================================================================================")
    print("SONY DIRECTOR 10/10 QUALITY AUDIT: Track L1-B Props")
    print("================================================================================================================")
    print(hdr)
    print("-" * len(hdr))
    all_ok = True
    for fname, (tmin, tmax), (hmin, hmax), (wmin, wmax) in TARGETS:
        path = os.path.join(PROPS_DIR, fname)
        if not os.path.exists(path):
            print(f"MISSING: {fname}")
            all_ok = False
            continue
        r = verify_glb(path)
        ok = (
            r["missing"] == 0 and r["nan"] == 0 and r["bad_n"] == 0 and
            r["degen"] == 0 and r["open"] == 0 and r["neg_vol"] == 0 and
            r["flipped"] == 0 and r["f_vn"] == 0 and r["sm_h"] == 0 and
            r["float"] == 0 and r["comps_3d"] == 1 and
            r["ds"] == 0 and r["non_op"] == 0 and
            abs(r["Y_min"]) < 1e-4 and
            tmin <= r["tris"] <= tmax and
            hmin <= r["H"] <= hmax
        )
        if not ok:
            all_ok = False
        dims = f"{r['W']:.1f}x{r['H']:.1f}x{r['D']:.1f}"
        print(
            f"{r['file']:25s} | {r['kb']:5.1f} | {r['tris']:5d} | {dims:18s} | {r['Y_min']:7.4f} | "
            f"{r['open']:3d} | {r['neg_vol']:3d} | {r['flipped']:3d} | {r['f_vn']:4d} | {r['sm_h']:4d} | "
            f"{r['comps_3d']:3d} | {r['float']:3d} | {r['ds']:2d} | {'PASS 10/10' if ok else 'FAIL'}"
        )
        if not ok:
            print("   DETAILS:", {k: v for k, v in r.items() if k not in ("file", "kb", "tris")})
    print("-" * len(hdr))
    print("OVERALL AUDIT RESULT:", "10/10 SONY QA PERFECT SCORE PASS!" if all_ok else "REVISIONS REQUIRED!")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
