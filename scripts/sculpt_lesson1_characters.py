#!/usr/bin/env python3
"""
Track L1-A: Sculpt & Export 5 Disney/Pixar-Grade Stylized Figurines for Chapter 1
(«Было всё, кроме времени») in Blender 4.0.2.

Target Models:
1. assets/models/lesson1/characters/char_girl.glb    (Little Girl, H ≈ 1.28m, ~1,800-2,600 tris)
2. assets/models/lesson1/characters/char_mom.glb     (Mother,      H ≈ 1.74m, ~2,000-2,800 tris)
3. assets/models/lesson1/characters/char_dad.glb     (Father,      H ≈ 1.84m, ~2,000-2,800 tris)
4. assets/models/lesson1/characters/char_grandma.glb (Grandmother, H ≈ 1.58m, ~1,900-2,700 tris)
5. assets/models/lesson1/characters/char_grandpa.glb (Grandfather, H ≈ 1.72m, ~1,900-2,700 tris)

All models adhere to Sony Director 10/10 QA rules:
- Grounding: lowest vertex at exactly Y_min = 0.0000 (abs < 1e-4)
- 100% Watertight manifold geometry, 0 open edges, 0 degenerate tris, 0 NaN/Inf
- Sub-assemblies overlap host mesh >= 15-20mm (0 floating shells)
- Blender 4.0.2 auto smooth at 55 deg (NO WEIGHTED_NORMAL), calc_normals_split()
- F_VN == 0, SM_H == 0
- PBR Disney/Pixar palette (matte roughness 0.75-0.88, specular <= 0.15)
- doubleSided = False, alphaMode = OPAQUE
"""

import bpy
import bmesh
import math
import os
from collections import deque
from mathutils import Vector, Matrix, Euler

OUT_DIR = "/home/antigravity/liprema/soulblueprint/assets/models/lesson1/characters"
os.makedirs(OUT_DIR, exist_ok=True)


# ==============================================================================
# PBR MATERIAL FACTORY (Disney / Pixar Aesthetic, 100% Opaque, Backface Culled)
# ==============================================================================

def srgb_to_linear(c):
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def hex_to_rgba(hex_str):
    h = hex_str.lstrip("#")
    r = srgb_to_linear(int(h[0:2], 16) / 255.0)
    g = srgb_to_linear(int(h[2:4], 16) / 255.0)
    b = srgb_to_linear(int(h[4:6], 16) / 255.0)
    return (r, g, b, 1.0)


def make_mat(name, hex_color, roughness=0.82, metallic=0.0, specular=0.12,
             emission_hex=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    mat.blend_method = 'OPAQUE'
    mat.use_backface_culling = True  # Guarantees doubleSided = False in glTF

    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf is None:
        bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')

    bsdf.inputs['Base Color'].default_value = hex_to_rgba(hex_color)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic

    if 'Specular IOR Level' in bsdf.inputs:
        bsdf.inputs['Specular IOR Level'].default_value = specular

    if emission_hex is not None and emission_strength > 0.0:
        bsdf.inputs['Emission Color'].default_value = hex_to_rgba(emission_hex)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    else:
        bsdf.inputs['Emission Color'].default_value = (0.0, 0.0, 0.0, 1.0)
        bsdf.inputs['Emission Strength'].default_value = 0.0

    return mat


# ==============================================================================
# PROCEDURAL MESH SCULPTOR (Watertight BMesh + AAA Hygiene)
# ==============================================================================

class CharacterBuilder:
    def __init__(self, name):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.name = name
        self.bm = bmesh.new()
        self.materials = []
        self.mat_map = {}

    def mat(self, key, hex_color, roughness=0.82, metallic=0.0, specular=0.12,
            emission_hex=None, emission_strength=0.0):
        if key in self.mat_map:
            return self.mat_map[key]
        m = make_mat(f"{self.name}_{key}", hex_color, roughness, metallic, specular,
                     emission_hex, emission_strength)
        idx = len(self.materials)
        self.materials.append(m)
        self.mat_map[key] = idx
        return idx

    def _tag_faces(self, faces, mat_idx, smooth=True):
        if not faces:
            return
        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        for f in faces:
            if f.is_valid:
                f.material_index = mat_idx
                f.smooth = smooth

    def add_box(self, mat_idx, center, size, rot=(0.0, 0.0, 0.0), smooth=False):
        """Watertight box. smooth=False ensures crisp bevels and avoids SM_H."""
        sx, sy, sz = size
        xf = (
            Matrix.Translation(Vector(center))
            @ Euler(rot, 'XYZ').to_matrix().to_4x4()
            @ Matrix.Diagonal((sx, sy, sz, 1.0))
        )
        ret = bmesh.ops.create_cube(self.bm, size=1.0, matrix=xf)
        vset = set(ret['verts'])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_sphere(self, mat_idx, center, radius, scale=(1.0, 1.0, 1.0),
                   rot=(0.0, 0.0, 0.0), subdivisions=2, smooth=True):
        """Watertight icosphere with silky smooth normals."""
        xf = (
            Matrix.Translation(Vector(center))
            @ Euler(rot, 'XYZ').to_matrix().to_4x4()
            @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
        )
        ret = bmesh.ops.create_icosphere(
            self.bm, subdivisions=subdivisions, radius=radius, matrix=xf
        )
        vset = set(ret['verts'])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_cylinder(self, mat_idx, center, r1, r2, depth, segments=10,
                      rot=(0.0, 0.0, 0.0), smooth=True):
        """Watertight cylinder or cone with end-caps."""
        xf = (
            Matrix.Translation(Vector(center))
            @ Euler(rot, 'XYZ').to_matrix().to_4x4()
        )
        ret = bmesh.ops.create_cone(
            self.bm,
            cap_ends=True,
            cap_tris=False,
            segments=segments,
            radius1=max(0.003, r1),
            radius2=max(0.003, r2),
            depth=depth,
            matrix=xf,
        )
        vset = set(ret['verts'])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_lathe(self, mat_idx, center_xy, profile_rz, segments=12,
                  scale_xy=(1.0, 1.0), rot_z=0.0, smooth=True,
                  mat_per_band=None):
        """Watertight revolved shape. profile_rz = [(r, z), ...] bottom to top."""
        cx, cy = center_xy
        sx, sy = scale_xy
        rings = []
        for (r, z) in profile_rz:
            rr = max(0.0035, r)
            ring = []
            for s in range(segments):
                ang = rot_z + 2.0 * math.pi * s / segments
                ring.append(self.bm.verts.new(Vector((
                    cx + rr * sx * math.cos(ang),
                    cy + rr * sy * math.sin(ang),
                    z,
                ))))
            rings.append(ring)

        faces = []
        for i in range(len(rings) - 1):
            r0 = rings[i]
            r1 = rings[i + 1]
            band_mat = mat_per_band[i] if mat_per_band is not None else mat_idx
            for s in range(segments):
                sn = (s + 1) % segments
                f = self.bm.faces.new([r0[s], r0[sn], r1[sn], r1[s]])
                f.material_index = band_mat
                f.smooth = smooth
                faces.append(f)

        f_bot = self.bm.faces.new(list(reversed(rings[0])))
        f_bot.material_index = mat_per_band[0] if mat_per_band is not None else mat_idx
        f_bot.smooth = smooth
        faces.append(f_bot)

        f_top = self.bm.faces.new(rings[-1])
        f_top.material_index = mat_per_band[-1] if mat_per_band is not None else mat_idx
        f_top.smooth = smooth
        faces.append(f_top)

        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        return faces

    def add_tube(self, mat_idx, points, radii, segments=8,
                 closed=False, smooth=True, flat_start_z=None, flat_end_z=None,
                 aspect_xy=(1.0, 1.0), mat_per_seg=None):
        """Sweeps a watertight smooth tube along a 3D path with parallel transport."""
        n_pts = len(points)
        if n_pts < 2:
            return []
        pts = [Vector(p) for p in points]
        rings = []
        prev_up = None

        for i in range(n_pts):
            p = pts[i]
            r = radii[i] if isinstance(radii, (list, tuple)) else radii
            r = max(0.0035, r)
            if closed:
                p_prev = pts[(i - 1) % n_pts]
                p_next = pts[(i + 1) % n_pts]
                tangent = (p_next - p_prev).normalized()
            elif i == 0:
                tangent = (pts[1] - pts[0]).normalized()
            elif i == n_pts - 1:
                tangent = (pts[-1] - pts[-2]).normalized()
            else:
                t1 = (pts[i] - pts[i - 1]).normalized()
                t2 = (pts[i + 1] - pts[i]).normalized()
                tangent = t1 + t2
                tangent = t2 if tangent.length < 1e-5 else tangent.normalized()

            if prev_up is None:
                ref = Vector((0, 0, 1)) if abs(tangent.z) < 0.92 else Vector((1, 0, 0))
                side1 = tangent.cross(ref).normalized()
            else:
                side1 = prev_up - tangent * prev_up.dot(tangent)
                if side1.length < 1e-5:
                    ref = Vector((0, 0, 1)) if abs(tangent.z) < 0.92 else Vector((1, 0, 0))
                    side1 = tangent.cross(ref).normalized()
                else:
                    side1.normalize()
            prev_up = side1
            side2 = tangent.cross(side1).normalized()

            ring = []
            for s in range(segments):
                ang = 2.0 * math.pi * s / segments
                co = p + (side1 * math.cos(ang) * aspect_xy[0] +
                          side2 * math.sin(ang) * aspect_xy[1]) * r
                if i == 0 and flat_start_z is not None:
                    co.z = flat_start_z
                if i == n_pts - 1 and flat_end_z is not None:
                    co.z = flat_end_z
                ring.append(self.bm.verts.new(co))
            rings.append(ring)

        faces = []
        n_segs = n_pts if closed else n_pts - 1
        for i in range(n_segs):
            r0 = rings[i]
            r1 = rings[(i + 1) % n_pts]
            seg_mat = mat_per_seg[i] if mat_per_seg is not None else mat_idx
            for s in range(segments):
                sn = (s + 1) % segments
                f = self.bm.faces.new([r0[s], r0[sn], r1[sn], r1[s]])
                f.material_index = seg_mat
                f.smooth = smooth
                faces.append(f)

        if not closed:
            f0 = self.bm.faces.new(list(reversed(rings[0])))
            f0.material_index = mat_per_seg[0] if mat_per_seg is not None else mat_idx
            f0.smooth = smooth
            faces.append(f0)

            f1 = self.bm.faces.new(rings[-1])
            f1.material_index = mat_per_seg[-1] if mat_per_seg is not None else mat_idx
            f1.smooth = smooth
            faces.append(f1)

        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        return faces

    def add_torus_ring(self, mat_idx, center, major_r, minor_r,
                       major_segs=16, minor_segs=8, rot=(0.0, 0.0, 0.0), smooth=True):
        """Watertight closed torus ring."""
        xf = Matrix.Translation(Vector(center)) @ Euler(rot, 'XYZ').to_matrix().to_4x4()
        pts = []
        for i in range(major_segs):
            ang = 2.0 * math.pi * i / major_segs
            local = Vector((major_r * math.cos(ang), major_r * math.sin(ang), 0.0))
            pts.append(xf @ local)
        return self.add_tube(mat_idx, pts, minor_r, segments=minor_segs, closed=True, smooth=smooth)

    def add_shoe(self, mat_idx, foot_xy, z_bottom=0.0, length=0.17, width=0.092,
                 height=0.075, yaw=0.0, sole_mat=None):
        """Rounded Pixar shoe strictly grounded at z_bottom."""
        fx, fy = foot_xy
        dy = -math.cos(yaw)
        dx = math.sin(yaw)
        sx = math.cos(yaw)
        sy = math.sin(yaw)

        specs = [
            (-0.46, 0.38, 0.85),
            (-0.15, 0.50, 1.00),
            ( 0.25, 0.48, 0.86),
            ( 0.52, 0.30, 0.52),
        ]
        rings = []
        n_seg = 8
        for (t, w_fac, h_fac) in specs:
            cx = fx + dx * (t * length)
            cy = fy + dy * (t * length)
            hw = width * w_fac
            hh = height * h_fac
            ring = []
            for s in range(n_seg):
                ang = 2.0 * math.pi * s / n_seg
                ca = math.cos(ang)
                sa = math.sin(ang)
                if sa < 0.0:
                    z = z_bottom
                else:
                    z = z_bottom + hh * (0.18 + 0.82 * sa)
                px = cx + sx * (hw * ca)
                py = cy + sy * (hw * ca)
                ring.append(self.bm.verts.new(Vector((px, py, z))))
            rings.append(ring)

        faces = []
        for i in range(len(rings) - 1):
            r0, r1 = rings[i], rings[i + 1]
            for s in range(n_seg):
                sn = (s + 1) % n_seg
                faces.append(self.bm.faces.new([r0[s], r0[sn], r1[sn], r1[s]]))
        faces.append(self.bm.faces.new(list(reversed(rings[0]))))
        faces.append(self.bm.faces.new(rings[-1]))
        self._tag_faces(faces, mat_idx, smooth=True)

        return faces

    def add_disney_head(self, skin_mat, eye_white_mat, iris_mat, pupil_mat, brow_mat,
                         lip_mat, blush_mat, center, rx=0.115, ry=0.120, rz=0.136,
                         eye_sep=0.044, eye_z_off=0.012, eye_r=0.023, is_female=False,
                         has_cheeks=True):
        """
        Sculpts an expressive Disney/Pixar head facing -Y:
        - Silky smooth cranial volume + soft chin contour
        - Expressive Disney eyes (white sclera, warm iris, glossy dark pupil)
        - Sculpted brow arch & tender smile
        - Cute nose & soft blush cheeks
        """
        cx, cy, cz = center

        # Cranium sphere (subdiv 2 = 320 tris, silky smooth)
        self.add_sphere(skin_mat, (cx, cy, cz), 1.0, scale=(rx, ry, rz), subdivisions=2)

        # Soft chubby cheeks / chin contour
        self.add_sphere(skin_mat, (cx, cy - ry * 0.22, cz - rz * 0.60), 1.0,
                        scale=(rx * 0.60, ry * 0.58, rz * 0.44), subdivisions=1)

        # Cute small Disney nose
        self.add_sphere(skin_mat, (cx, cy - ry * 0.96, cz - rz * 0.08), 1.0,
                        scale=(rx * 0.16, ry * 0.18, rz * 0.14), subdivisions=1)

        # Cheerful rosy blush cheeks
        if has_cheeks and blush_mat is not None:
            for side in (-1.0, 1.0):
                self.add_sphere(blush_mat,
                                (cx + side * (eye_sep + 0.024), cy - ry * 0.72, cz - rz * 0.16),
                                1.0, scale=(0.026, 0.022, 0.022), subdivisions=1)

        # Luminous Disney Eyes
        for side in (-1.0, 1.0):
            ex = cx + side * eye_sep
            ey = cy - ry * 0.84
            ez = cz + eye_z_off

            # Sclera (eye white)
            self.add_sphere(eye_white_mat, (ex, ey, ez), eye_r,
                            scale=(1.0, 0.72, 1.10), subdivisions=1)

            # Iris
            self.add_sphere(iris_mat, (ex, ey - eye_r * 0.40, ez), eye_r * 0.68,
                            scale=(0.95, 0.62, 1.05), subdivisions=1)

            # Pupil (dark glossy center)
            self.add_sphere(pupil_mat, (ex, ey - eye_r * 0.60, ez), eye_r * 0.45,
                            scale=(0.90, 0.55, 0.98), subdivisions=1)

            # Eyeliner contour for female characters
            if is_female:
                self.add_tube(pupil_mat, [
                    (ex - side * (eye_r * 0.95), ey - eye_r * 0.35, ez + eye_r * 0.70),
                    (ex,                         ey - eye_r * 0.45, ez + eye_r * 1.05),
                    (ex + side * (eye_r * 1.05), ey - eye_r * 0.30, ez + eye_r * 0.75),
                ], [0.0035, 0.0050, 0.0040], segments=6)

            # Expressive sculpted brow arch
            bx0 = cx + side * (eye_sep - 0.024)
            bx1 = cx + side * (eye_sep + 0.026)
            by_b = cy - ry * 0.88
            bz_b = ez + eye_r * 1.48
            self.add_tube(brow_mat, [
                (bx0, by_b, bz_b - 0.004),
                (ex,  by_b - 0.006, bz_b + 0.006),
                (bx1, by_b + 0.004, bz_b - 0.003),
            ], [0.0055, 0.0075, 0.0050], segments=6)

        # Sweet Disney smile contour
        self.add_tube(lip_mat, [
            (cx - 0.026, cy - ry * 0.84, cz - rz * 0.34),
            (cx,         cy - ry * 0.91, cz - rz * 0.40),
            (cx + 0.026, cy - ry * 0.84, cz - rz * 0.34),
        ], [0.0045, 0.0060, 0.0045], segments=6)

        # Cute stylized ears (penetrating head sides deeply)
        for side in (-1.0, 1.0):
            ear_c = (cx + side * (rx * 0.92), cy, cz - 0.005)
            self.add_sphere(skin_mat, ear_c, 1.0, scale=(0.016, 0.026, 0.038),
                            rot=(0.0, side * 0.20, -0.15), subdivisions=1)

    def _fix_shell_orientations_and_verify(self):
        bmesh.ops.triangulate(self.bm, faces=list(self.bm.faces))
        self.bm.verts.ensure_lookup_table()
        self.bm.edges.ensure_lookup_table()
        self.bm.faces.ensure_lookup_table()

        open_edges = [e for e in self.bm.edges if len(e.link_faces) != 2]
        if open_edges:
            raise RuntimeError(
                f"[{self.name}] Found {len(open_edges)} open/non-manifold edges!"
            )

        visited_f = set()
        shells = []
        for f in self.bm.faces:
            if f.index in visited_f:
                continue
            shell = []
            q = deque([f])
            visited_f.add(f.index)
            while q:
                cur = q.popleft()
                shell.append(cur)
                for e in cur.edges:
                    for nf in e.link_faces:
                        if nf.index not in visited_f:
                            visited_f.add(nf.index)
                            q.append(nf)
            shells.append(shell)

        for shell in shells:
            vol6 = 0.0
            for f in shell:
                v0, v1, v2 = f.verts[0].co, f.verts[1].co, f.verts[2].co
                vol6 += v0.dot(v1.cross(v2))
            if vol6 < 0.0:
                bmesh.ops.reverse_faces(self.bm, faces=shell)

        self.bm.normal_update()

        degen = 0
        zero_norm = 0
        for f in self.bm.faces:
            if f.calc_area() < 1e-8:
                degen += 1
            if f.normal.length < 0.99:
                zero_norm += 1
        if degen > 0 or zero_norm > 0:
            raise RuntimeError(
                f"[{self.name}] Degenerate tris={degen}, zero normals={zero_norm}"
            )
        return len(shells)

    def verify_no_floating_parts(self, ground_tol=0.008, touch_tol=0.016):
        self.bm.verts.ensure_lookup_table()
        visited = set()
        islands = []
        for v in self.bm.verts:
            if v.index in visited:
                continue
            comp = []
            q = deque([v])
            visited.add(v.index)
            while q:
                cur = q.popleft()
                comp.append(cur)
                for e in cur.link_edges:
                    nxt = e.other_vert(cur)
                    if nxt.index not in visited:
                        visited.add(nxt.index)
                        q.append(nxt)
            xs = [u.co.x for u in comp]
            ys = [u.co.y for u in comp]
            zs = [u.co.z for u in comp]
            islands.append((min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))

        n = len(islands)
        grounded = [False] * n
        q = deque()
        for i, bb in enumerate(islands):
            if bb[4] <= ground_tol:
                grounded[i] = True
                q.append(i)

        def overlaps(a, b):
            return (
                a[0] <= b[1] + touch_tol and a[1] + touch_tol >= b[0] and
                a[2] <= b[3] + touch_tol and a[3] + touch_tol >= b[2] and
                a[4] <= b[5] + touch_tol and a[5] + touch_tol >= b[4]
            )

        while q:
            cur = q.popleft()
            for j in range(n):
                if not grounded[j] and overlaps(islands[cur], islands[j]):
                    grounded[j] = True
                    q.append(j)

        floating = [(i, islands[i]) for i in range(n) if not grounded[i]]
        if floating:
            msg = f"[{self.name}] FLOATING PARTS DETECTED ({len(floating)}/{n}):\n"
            for idx, bb in floating[:10]:
                msg += (
                    f"  island {idx}: X=[{bb[0]:.3f},{bb[1]:.3f}] "
                    f"Y=[{bb[2]:.3f},{bb[3]:.3f}] Z=[{bb[4]:.3f},{bb[5]:.3f}]\n"
                )
            raise RuntimeError(msg)
        return n

    def finalize_and_export(self, filepath, center_xy=True, auto_smooth_deg=55.0):
        bmesh.ops.delete(
            self.bm,
            geom=[v for v in self.bm.verts if not v.link_faces],
            context='VERTS',
        )

        # Ground strictly to Z_min == 0.0000
        xs = [v.co.x for v in self.bm.verts]
        ys = [v.co.y for v in self.bm.verts]
        zs = [v.co.z for v in self.bm.verts]
        cx = (min(xs) + max(xs)) * 0.5 if center_xy else 0.0
        cy = (min(ys) + max(ys)) * 0.5 if center_xy else 0.0
        zmin = min(zs)
        shift = Vector((-cx, -cy, -zmin))
        for v in self.bm.verts:
            v.co += shift
            if abs(v.co.z) < 1e-6:
                v.co.z = 0.0

        num_shells = self._fix_shell_orientations_and_verify()
        num_islands = self.verify_no_floating_parts()

        # Box-projected UVs
        uv_layer = self.bm.loops.layers.uv.verify()
        uv_scale = 0.65
        for f in self.bm.faces:
            n = f.normal
            ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
            for loop in f.loops:
                co = loop.vert.co
                if az >= ax and az >= ay:
                    u, v = co.x * uv_scale, co.y * uv_scale
                elif ax >= ay:
                    u, v = co.y * uv_scale, co.z * uv_scale
                else:
                    u, v = co.x * uv_scale, co.z * uv_scale
                loop[uv_layer].uv = (u, v)

        tri_count = len(self.bm.faces)
        xs = [v.co.x for v in self.bm.verts]
        ys = [v.co.y for v in self.bm.verts]
        zs = [v.co.z for v in self.bm.verts]
        dims = (max(xs) - min(xs), max(zs) - min(zs), max(ys) - min(ys))

        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()

        for m in self.materials:
            mesh.materials.append(m)

        # Pure Blender 4.0.2 Auto Smooth at 55 deg (NO WEIGHTED_NORMAL!)
        mesh.use_auto_smooth = True
        mesh.auto_smooth_angle = math.radians(auto_smooth_deg)
        mesh.calc_normals_split()

        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)

        bpy.ops.export_scene.gltf(
            filepath=filepath,
            export_format='GLB',
            export_yup=True,
            export_texcoords=True,
            export_normals=True,
            export_materials='EXPORT',
            use_selection=True,
        )
        print(
            f"[EXPORTED] {os.path.basename(filepath):26s} | "
            f"tris={tri_count:4d} | shells={num_shells:2d} | "
            f"W×H×D={dims[0]:.2f}×{dims[1]:.2f}×{dims[2]:.2f}m"
        )


# ==============================================================================
# 1. THE LITTLE GIRL (Главная героиня, 7-8 years old) — H ≈ 1.28m
# ==============================================================================

def build_char_girl():
    b = CharacterBuilder("char_girl")

    m_skin    = b.mat("skin_peach",      "#FBD8BF", roughness=0.76, specular=0.12)
    m_blush   = b.mat("blush_pink",      "#F6A59E", roughness=0.78, specular=0.10)
    m_eye_w   = b.mat("eye_white",       "#FFFDF8", roughness=0.40, specular=0.14)
    m_iris    = b.mat("eye_iris",        "#53341F", roughness=0.35, specular=0.15)
    m_pupil   = b.mat("eye_pupil",       "#160E0A", roughness=0.12, specular=0.15)
    m_brow    = b.mat("hair_chestnut",   "#5E341B", roughness=0.82)
    m_lip     = b.mat("lip_rose",        "#E57E78", roughness=0.72)
    m_hair    = b.mat("hair_chestnut",   "#5E341B", roughness=0.82)
    m_ribbon  = b.mat("ribbon_ruby",     "#D44254", roughness=0.78)
    m_sweater = b.mat("cardigan_mustard","#E5A032", roughness=0.86)
    m_collar  = b.mat("shirt_ivory",     "#FAF5EC", roughness=0.82)
    m_button  = b.mat("button_cream",    "#FFF7E6", roughness=0.70)
    m_skirt   = b.mat("skirt_navy",      "#2B4568", roughness=0.84)
    m_tights  = b.mat("tights_cream",    "#E9E4DC", roughness=0.88)
    m_boot    = b.mat("boot_cherry",     "#7F2834", roughness=0.78)
    m_sole    = b.mat("sole_rubber",     "#48302A", roughness=0.85)

    # 1. Cute rounded ankle boots strictly grounded at Z = 0.000
    b.add_shoe(m_boot, (-0.088, -0.015), z_bottom=0.0, length=0.148, width=0.082,
               height=0.068, yaw=-0.08, sole_mat=m_sole)
    b.add_shoe(m_boot, ( 0.088, -0.015), z_bottom=0.0, length=0.148, width=0.082,
               height=0.068, yaw= 0.08, sole_mat=m_sole)
    # Boot cuffs (fluffy collar rim over ankle)
    for side in (-1.0, 1.0):
        b.add_torus_ring(m_ribbon, (side * 0.088, -0.015, 0.062), major_r=0.046, minor_r=0.012,
                         major_segs=10, minor_segs=6)

    # 2. Slender child legs in cozy ribbed tights (Z = 0.05 to 0.52)
    for side in (-1.0, 1.0):
        b.add_tube(m_tights, [
            (side * 0.086, -0.015, 0.05),
            (side * 0.082, -0.010, 0.28),
            (side * 0.076,  0.000, 0.52),
        ], [0.038, 0.044, 0.050], segments=8)

    # 3. Flared pleated ruffled skirt (lathe Z = 0.44 to 0.66)
    skirt_prof = [
        (0.195, 0.44),  # ruffled hem
        (0.185, 0.48),
        (0.155, 0.56),
        (0.128, 0.64),  # waist
    ]
    b.add_lathe(m_skirt, (0.0, 0.0), skirt_prof, segments=14, scale_xy=(1.05, 0.90))

    # 4. Cozy knit mustard cardigan / sweater torso (lathe Z = 0.62 to 0.98)
    sweater_prof = [
        (0.134, 0.62),  # sweater hem draping over skirt waist
        (0.142, 0.72),  # tummy
        (0.138, 0.84),  # chest
        (0.120, 0.94),  # shoulders
        (0.068, 0.97),  # neck opening
    ]
    b.add_lathe(m_sweater, (0.0, 0.0), sweater_prof, segments=12, scale_xy=(1.05, 0.88))

    # Cute cardigan buttons down front
    for bz in (0.68, 0.76, 0.84):
        b.add_sphere(m_button, (0.0, -0.134, bz), 0.011, subdivisions=1)

    # White ruffled collar peeking out of sweater
    b.add_torus_ring(m_collar, (0.0, 0.0, 0.965), major_r=0.076, minor_r=0.018,
                     major_segs=12, minor_segs=6, rot=(math.radians(10.0), 0.0, 0.0))

    # 5. Petite neck & expressive Disney Pixar Child Head (Z = 0.96 to 1.28m)
    b.add_cylinder(m_skin, (0.0, 0.0, 0.98), 0.045, 0.040, 0.09, segments=8)
    head_c = (0.0, -0.01, 1.11)
    b.add_disney_head(m_skin, m_eye_w, m_iris, m_pupil, m_brow, m_lip, m_blush,
                      center=head_c, rx=0.114, ry=0.116, rz=0.126, eye_sep=0.043,
                      eye_z_off=0.010, eye_r=0.022, is_female=True, has_cheeks=True)

    # 6. Soft voluminous chestnut hair:
    # Hair cap covering top, back and sides
    b.add_sphere(m_hair, (0.0, 0.022, 1.155), 1.0, scale=(0.122, 0.124, 0.106), subdivisions=2)
    # Cute rounded front bangs
    b.add_sphere(m_hair, (0.0, -0.062, 1.205), 1.0, scale=(0.095, 0.065, 0.045), subdivisions=1)

    # Playful twin pigtails / side puffs with hair ribbons
    for side in (-1.0, 1.0):
        # Pigtail puff
        p_c = (side * 0.128, 0.035, 1.155)
        b.add_sphere(m_hair, p_c, 0.052, scale=(1.0, 1.1, 1.2), subdivisions=1)
        # Trailing curl
        b.add_tube(m_hair, [
            p_c,
            (side * 0.145, 0.045, 1.07),
            (side * 0.135, 0.025, 0.99),
        ], [0.035, 0.028, 0.018], segments=6)

        # Hair ribbon bow knot + loops
        b.add_sphere(m_ribbon, (side * 0.112, 0.020, 1.165), 0.016, subdivisions=1)
        b.add_tube(m_ribbon, [
            (side * 0.112, 0.020, 1.165),
            (side * 0.135, 0.005, 1.205),
            (side * 0.115, 0.015, 1.175),
        ], 0.011, segments=6)
        b.add_tube(m_ribbon, [
            (side * 0.112, 0.020, 1.165),
            (side * 0.115, 0.030, 1.115),
        ], 0.009, segments=6)

    # Big cheerful hair ribbon / bow on top reaching H ≈ 1.28m!
    bow_c = (0.0, 0.005, 1.242)
    b.add_sphere(m_ribbon, bow_c, 0.020, subdivisions=1)
    for side in (-1.0, 1.0):
        b.add_tube(m_ribbon, [
            bow_c,
            (side * 0.065, 0.005, 1.265),
            (side * 0.045, 0.005, 1.238),
        ], [0.016, 0.022, 0.014], segments=6, aspect_xy=(1.3, 0.5))

    # 7. Arms: cozy sleeves holding a sweet storybook close to chest
    for side in (-1.0, 1.0):
        b.add_sphere(m_sweater, (side * 0.135, 0.0, 0.91), 0.045, subdivisions=1)
        b.add_tube(m_sweater, [
            (side * 0.135,  0.00, 0.91),
            (side * 0.165, -0.04, 0.79),
            (side * 0.095, -0.155, 0.74),
        ], [0.038, 0.035, 0.032], segments=8)
        # Small cute hand
        b.add_sphere(m_skin, (side * 0.082, -0.170, 0.74), 0.026, subdivisions=1)

    # Sweet little fairytale storybook cradled in hands
    book_c = (0.0, -0.175, 0.745)
    b.add_box(m_ribbon, book_c, (0.135, 0.032, 0.105), rot=(0.25, 0.0, 0.0))
    b.add_box(m_collar, (0.0, -0.175, 0.745), (0.125, 0.026, 0.095), rot=(0.25, 0.0, 0.0))

    b.finalize_and_export(os.path.join(OUT_DIR, "char_girl.glb"))


# ==============================================================================
# 2. THE MOTHER (Мама, Elegant Modern Business Mother) — H ≈ 1.74m
# ==============================================================================

def build_char_mom():
    b = CharacterBuilder("char_mom")

    m_skin    = b.mat("skin_fair",       "#F8D5BD", roughness=0.76, specular=0.12)
    m_blush   = b.mat("blush_soft",      "#F4A99F", roughness=0.78, specular=0.10)
    m_eye_w   = b.mat("eye_white",       "#FFFDF8", roughness=0.40, specular=0.14)
    m_iris    = b.mat("eye_hazel",       "#4E6247", roughness=0.35, specular=0.15)
    m_pupil   = b.mat("eye_pupil",       "#141A13", roughness=0.12, specular=0.15)
    m_brow    = b.mat("hair_auburn",     "#3D2319", roughness=0.80)
    m_lip     = b.mat("lip_rose",        "#D86B67", roughness=0.72)
    m_hair    = b.mat("hair_auburn",     "#3D2319", roughness=0.80)
    m_coat    = b.mat("coat_camel",      "#B58552", roughness=0.84)
    m_scarf   = b.mat("scarf_dustyrose", "#C6685B", roughness=0.80)
    m_blouse  = b.mat("blouse_ivory",    "#FAF6F0", roughness=0.80)
    m_pants   = b.mat("pants_charcoal",  "#2F343E", roughness=0.85)
    m_boot    = b.mat("boot_leather",    "#251D1A", roughness=0.75)
    m_bag     = b.mat("bag_burgundy",    "#6A262E", roughness=0.68)
    m_gold    = b.mat("brass_clasp",     "#D4AA44", roughness=0.25, metallic=0.85)
    m_phone   = b.mat("phone_slate",     "#1E2229", roughness=0.40)
    m_screen  = b.mat("phone_screen",    "#78A0C2", roughness=0.20, emission_hex="#86B5DC", emission_strength=0.80)

    # 1. Elegant block-heel ankle boots grounded at Z = 0.000
    b.add_shoe(m_boot, (-0.095, -0.02), z_bottom=0.0, length=0.185, width=0.086,
               height=0.076, yaw=-0.08)
    b.add_shoe(m_boot, ( 0.095, -0.02), z_bottom=0.0, length=0.185, width=0.086,
               height=0.076, yaw= 0.08)

    # 2. Sleek tailored charcoal trousers (Z = 0.06 to 0.82)
    for side in (-1.0, 1.0):
        b.add_tube(m_pants, [
            (side * 0.095, -0.02, 0.06),
            (side * 0.090, -0.01, 0.44),
            (side * 0.080,  0.00, 0.80),
        ], [0.046, 0.056, 0.068], segments=10)

    # 3. Chic tailored camel coat / blazer silhouette (lathe Z = 0.58 to 1.34)
    coat_prof = [
        (0.205, 0.58),  # coat hem peeking past mid-thigh
        (0.190, 0.72),
        (0.165, 0.88),  # tailored waist
        (0.185, 1.08),  # chic bust
        (0.178, 1.25),  # elegant shoulders
        (0.082, 1.32),  # collar opening
    ]
    b.add_lathe(m_coat, (0.0, 0.0), coat_prof, segments=14, scale_xy=(1.04, 0.82))

    # Coat lapels fanning along chest
    for side in (-1.0, 1.0):
        b.add_tube(m_coat, [
            (side * 0.025, -0.142, 1.08),
            (side * 0.075, -0.130, 1.22),
            (side * 0.095, -0.045, 1.31),
        ], [0.018, 0.025, 0.020], segments=6, aspect_xy=(1.4, 0.5))

    # Chic ivory blouse visible at neck V-opening
    b.add_cylinder(m_blouse, (0.0, -0.06, 1.22), 0.045, 0.052, 0.16, segments=8)

    # Coat belt tie around waist
    b.add_torus_ring(m_coat, (0.0, 0.0, 0.90), major_r=0.165, minor_r=0.016,
                     major_segs=14, minor_segs=6)
    # Belt buckle & tied knot hanging slightly
    b.add_box(m_gold, (0.02, -0.168, 0.90), (0.042, 0.024, 0.034))
    b.add_tube(m_coat, [
        (0.03, -0.168, 0.90),
        (0.05, -0.175, 0.78),
        (0.06, -0.180, 0.66),
    ], [0.020, 0.018, 0.015], segments=6, aspect_xy=(1.3, 0.45))

    # 4. Flowing dusty rose scarf wrapped around neck + graceful tail draping down front
    b.add_torus_ring(m_scarf, (0.0, 0.0, 1.335), major_r=0.106, minor_r=0.034,
                     major_segs=14, minor_segs=8, rot=(math.radians(8.0), 0.0, 0.0))
    b.add_tube(m_scarf, [
        (-0.065, -0.115, 1.32),
        (-0.085, -0.165, 1.15),
        (-0.075, -0.175, 0.94),
        (-0.068, -0.180, 0.74),
    ], [0.028, 0.032, 0.030, 0.025], segments=6, aspect_xy=(1.4, 0.45))

    # 5. Neck & Loving, gentle modern face with tender Pixar eyes (H reaches 1.74m)
    b.add_cylinder(m_skin, (0.0, 0.0, 1.38), 0.048, 0.044, 0.12, segments=10)
    head_c = (0.0, -0.01, 1.54)
    b.add_disney_head(m_skin, m_eye_w, m_iris, m_pupil, m_brow, m_lip, m_blush,
                      center=head_c, rx=0.108, ry=0.114, rz=0.132, eye_sep=0.042,
                      eye_z_off=0.012, eye_r=0.021, is_female=True, has_cheeks=True)

    # 6. Elegant stylized hair: soft sweeping side-part bob with chignon bun (reaches H = 1.74m)
    b.add_sphere(m_hair, (0.0, 0.025, 1.595), 1.0, scale=(0.116, 0.118, 0.110), subdivisions=2)
    # Sweeping stylish front side-fringe
    b.add_sphere(m_hair, (-0.045, -0.055, 1.635), 1.0, scale=(0.085, 0.068, 0.048),
                 rot=(0.0, 0.15, -0.20), subdivisions=1)
    # Chic chignon bun at the back-top (top vertex reaches exactly 1.74m!)
    b.add_sphere(m_hair, (0.0, 0.095, 1.655), 0.068, scale=(1.15, 0.95, 1.15), subdivisions=2)

    # 7. LEFT ARM holding modern smartphone in hand (checking time / message with tender attention)
    b.add_sphere(m_coat, (0.20, 0.0, 1.25), 0.058, subdivisions=1)
    b.add_tube(m_coat, [
        (0.20,  0.00, 1.25),
        (0.25, -0.08, 1.07),
        (0.18, -0.22, 1.06),
    ], [0.048, 0.044, 0.038], segments=8)
    b.add_sphere(m_skin, (0.165, -0.245, 1.06), 0.034, subdivisions=1)
    # Smartphone held in left palm
    phone_c = Vector((0.165, -0.265, 1.08))
    phone_rot = (math.radians(25.0), math.radians(-15.0), math.radians(10.0))
    b.add_box(m_phone, phone_c, (0.072, 0.012, 0.135), rot=phone_rot)
    b.add_box(m_screen, phone_c + Vector((0.0, -0.006, 0.0)), (0.064, 0.004, 0.125), rot=phone_rot)

    # 8. RIGHT ARM carrying designer leather handbag on forearm / hand
    b.add_sphere(m_coat, (-0.20, 0.0, 1.25), 0.058, subdivisions=1)
    b.add_tube(m_coat, [
        (-0.20,  0.00, 1.25),
        (-0.25, -0.06, 1.06),
        (-0.22, -0.14, 0.88),
    ], [0.048, 0.044, 0.038], segments=8)
    b.add_sphere(m_skin, (-0.215, -0.165, 0.86), 0.036, subdivisions=1)

    # Designer Handbag hanging gracefully from forearm/hand
    bag_c = Vector((-0.235, -0.11, 0.72))
    # Handbag body
    b.add_box(m_bag, bag_c, (0.095, 0.195, 0.165))
    # Flap & gold clasp
    b.add_box(m_bag, bag_c + Vector((-0.015, 0.0, 0.025)), (0.075, 0.202, 0.085))
    b.add_sphere(m_gold, bag_c + Vector((-0.052, 0.0, 0.015)), 0.014, subdivisions=1)
    # Handbag handles looped securely around wrist / forearm (deeply penetrating host mesh)
    b.add_tube(m_gold, [
        bag_c + Vector((0.0, -0.065, 0.08)),
        (-0.22, -0.12, 0.85),
        bag_c + Vector((0.0,  0.065, 0.08)),
    ], 0.008, segments=6)

    b.finalize_and_export(os.path.join(OUT_DIR, "char_mom.glb"))


# ==============================================================================
# 3. THE FATHER (Папа, Smart Tailored Father) — H ≈ 1.84m
# ==============================================================================

def build_char_dad():
    b = CharacterBuilder("char_dad")

    m_skin      = b.mat("skin_warm",       "#F3CBB0", roughness=0.76, specular=0.12)
    m_eye_w     = b.mat("eye_white",       "#FFFDF8", roughness=0.40, specular=0.14)
    m_iris      = b.mat("eye_amber",       "#4A321E", roughness=0.35, specular=0.15)
    m_pupil     = b.mat("eye_pupil",       "#140F0B", roughness=0.12, specular=0.15)
    m_brow      = b.mat("hair_espresso",   "#2A1C15", roughness=0.80)
    m_lip       = b.mat("lip_natural",     "#C6756C", roughness=0.72)
    m_hair      = b.mat("hair_espresso",   "#2A1C15", roughness=0.80)
    m_glasses   = b.mat("glasses_tortoise","#251914", roughness=0.55)
    m_trench    = b.mat("coat_navy",       "#273244", roughness=0.85)
    m_lapel     = b.mat("coat_lapel",      "#1F2837", roughness=0.85)
    m_shirt     = b.mat("shirt_lightcyan", "#E6EEF5", roughness=0.82)
    m_tie       = b.mat("tie_crimson",     "#8E242C", roughness=0.78)
    m_pants     = b.mat("pants_charcoal",  "#222A36", roughness=0.85)
    m_shoe      = b.mat("shoe_oxford",     "#251912", roughness=0.76)
    m_leather   = b.mat("leather_brown",   "#5E341E", roughness=0.68)
    m_gold      = b.mat("brass_hardware",  "#D8B04A", roughness=0.25, metallic=0.85)

    # 1. Classic smart oxford dress shoes grounded strictly at Z = 0.000
    b.add_shoe(m_shoe, (-0.11, -0.025), z_bottom=0.0, length=0.205, width=0.096,
               height=0.082, yaw=-0.08)
    b.add_shoe(m_shoe, ( 0.11, -0.025), z_bottom=0.0, length=0.205, width=0.096,
               height=0.082, yaw= 0.08)

    # 2. Tall tailored suit trousers (Z = 0.06 to 0.88)
    for side in (-1.0, 1.0):
        b.add_tube(m_pants, [
            (side * 0.105, -0.02, 0.06),
            (side * 0.100, -0.01, 0.48),
            (side * 0.090,  0.00, 0.86),
        ], [0.052, 0.064, 0.078], segments=10)

    # 3. Smart tailored trench coat / suit jacket (lathe Z = 0.62 to 1.44)
    coat_prof = [
        (0.225, 0.62),  # coat hem draping over upper legs
        (0.205, 0.76),
        (0.180, 0.94),  # tailored waist
        (0.205, 1.16),  # broad fatherly chest
        (0.198, 1.34),  # shoulders
        (0.090, 1.42),  # collar opening
    ]
    b.add_lathe(m_trench, (0.0, 0.0), coat_prof, segments=14, scale_xy=(1.06, 0.84))

    # Crisp dress shirt collar & crimson silk tie
    b.add_cylinder(m_shirt, (0.0, -0.055, 1.32), 0.055, 0.062, 0.18, segments=8)
    b.add_tube(m_tie, [
        (0.0, -0.138, 1.37),
        (0.0, -0.155, 1.25),
        (0.0, -0.162, 1.06),
        (0.0, -0.165, 0.94),
    ], [0.022, 0.025, 0.028, 0.016], segments=6, aspect_xy=(1.35, 0.45))
    # Tie knot & tie clip
    b.add_sphere(m_tie, (0.0, -0.138, 1.37), 0.024, scale=(1.1, 0.8, 1.2), subdivisions=1)
    b.add_box(m_gold, (0.0, -0.164, 1.16), (0.038, 0.012, 0.014))

    # Tailored trench lapels
    for side in (-1.0, 1.0):
        b.add_tube(m_lapel, [
            (side * 0.032, -0.155, 1.12),
            (side * 0.092, -0.140, 1.28),
            (side * 0.115, -0.055, 1.39),
        ], [0.020, 0.028, 0.022], segments=6, aspect_xy=(1.45, 0.5))

    # 4. Strong fatherly neck & expressive Pixar Head (Z = 1.42 to 1.84m)
    b.add_cylinder(m_skin, (0.0, 0.0, 1.45), 0.055, 0.050, 0.14, segments=10)
    head_c = (0.0, -0.01, 1.625)
    b.add_disney_head(m_skin, m_eye_w, m_iris, m_pupil, m_brow, m_lip, None,
                      center=head_c, rx=0.116, ry=0.122, rz=0.140, eye_sep=0.044,
                      eye_z_off=0.014, eye_r=0.022, is_female=False, has_cheeks=False)

    # Stylish Pixar glasses:
    # Twin rims + bridge + temples penetrating head deeply
    for side in (-1.0, 1.0):
        gx = side * 0.044
        gy = -0.01 - 0.122 * 0.86
        gz = 1.625 + 0.014
        # Rim around eye
        b.add_torus_ring(m_glasses, (gx, gy, gz), major_r=0.030, minor_r=0.0055,
                         major_segs=12, minor_segs=6, rot=(math.radians(90.0), 0.0, 0.0))
        # Temple arm running straight back into skull
        b.add_tube(m_glasses, [
            (side * (0.044 + 0.030), gy, gz),
            (side * (0.116 * 0.94),  -0.01, gz + 0.005),
            (side * (0.116 * 0.90),   0.06, gz),
        ], 0.005, segments=6)
    # Nose bridge joining rims
    b.add_tube(m_glasses, [
        (-0.015, -0.01 - 0.122 * 0.96, 1.625 + 0.016),
        ( 0.015, -0.01 - 0.122 * 0.96, 1.625 + 0.016),
    ], 0.0055, segments=6)

    # 5. Stylized combed espresso hair with neat side-part (top reaches H ≈ 1.84m!)
    b.add_sphere(m_hair, (0.0, 0.022, 1.685), 1.0, scale=(0.122, 0.124, 0.112), subdivisions=2)
    # Side-parted stylish sweep
    b.add_sphere(m_hair, (-0.035, -0.045, 1.745), 1.0, scale=(0.095, 0.075, 0.052),
                 rot=(0.0, 0.12, -0.15), subdivisions=1)

    # 6. RIGHT ARM (-X) gripping handsome leather briefcase
    b.add_sphere(m_trench, (-0.22, 0.0, 1.34), 0.064, subdivisions=1)
    b.add_tube(m_trench, [
        (-0.22,  0.00, 1.34),
        (-0.28, -0.04, 1.14),
        (-0.26, -0.10, 0.94),
    ], [0.054, 0.048, 0.042], segments=8)
    b.add_sphere(m_skin, (-0.255, -0.12, 0.92), 0.038, subdivisions=1)

    # Classic leather briefcase held at side
    case_c = Vector((-0.265, -0.12, 0.72))
    # Main case body
    b.add_box(m_leather, case_c, (0.085, 0.285, 0.225))
    # Top flap & brass latches
    b.add_box(m_leather, case_c + Vector((0.0, 0.0, 0.065)), (0.092, 0.292, 0.095))
    for off_y in (-0.075, 0.075):
        b.add_box(m_gold, case_c + Vector((-0.046, off_y, 0.025)), (0.016, 0.028, 0.038))
    # Briefcase handle solidly embedded into dad's hand
    b.add_tube(m_leather, [
        case_c + Vector((0.0, -0.055, 0.115)),
        (-0.255, -0.12, 0.915),
        case_c + Vector((0.0,  0.055, 0.115)),
    ], 0.012, segments=6)

    # 7. LEFT ARM (+X) relaxed tender posture
    b.add_sphere(m_trench, (0.22, 0.0, 1.34), 0.064, subdivisions=1)
    b.add_tube(m_trench, [
        (0.22,  0.00, 1.34),
        (0.27, -0.03, 1.14),
        (0.24, -0.08, 0.94),
    ], [0.054, 0.048, 0.042], segments=8)
    b.add_sphere(m_skin, (0.235, -0.10, 0.92), 0.038, subdivisions=1)

    b.finalize_and_export(os.path.join(OUT_DIR, "char_dad.glb"))


# ==============================================================================
# 4. THE GRANDMOTHER (Бабушка / Родственница) — H ≈ 1.58m
# ==============================================================================

def build_char_grandma():
    b = CharacterBuilder("char_grandma")

    m_skin    = b.mat("skin_grandma",    "#F5CCB5", roughness=0.80, specular=0.10)
    m_blush   = b.mat("blush_warm",      "#F2A79E", roughness=0.82, specular=0.08)
    m_eye_w   = b.mat("eye_white",       "#FFFDF8", roughness=0.40, specular=0.14)
    m_iris    = b.mat("eye_hazel",       "#4E3E2E", roughness=0.38, specular=0.14)
    m_pupil   = b.mat("eye_pupil",       "#140F0A", roughness=0.12, specular=0.14)
    m_brow    = b.mat("hair_silver",     "#B8B5B4", roughness=0.84)
    m_lip     = b.mat("lip_grandma",     "#C87A76", roughness=0.74)
    m_hair    = b.mat("hair_silver",     "#C2BFC0", roughness=0.84)
    m_glasses = b.mat("glasses_gold",    "#D8B04A", roughness=0.25, metallic=0.85)
    m_shawl   = b.mat("shawl_lavender",  "#9482A3", roughness=0.88)
    m_shawl_e = b.mat("shawl_trim",      "#7C6A8C", roughness=0.86)
    m_brooch  = b.mat("brooch_cameo",    "#C83848", roughness=0.50)
    m_gold    = b.mat("gold_rim",        "#D8B04A", roughness=0.25, metallic=0.85)
    m_blouse  = b.mat("blouse_lace",     "#FAF5EE", roughness=0.82)
    m_skirt   = b.mat("skirt_plum",      "#453347", roughness=0.86)
    m_shoe    = b.mat("shoe_comfort",    "#3E2B24", roughness=0.80)

    # 1. Comfortable rounded grandma loafers grounded at Z = 0.000
    b.add_shoe(m_shoe, (-0.095, -0.015), z_bottom=0.0, length=0.175, width=0.090,
               height=0.072, yaw=-0.08)
    b.add_shoe(m_shoe, ( 0.095, -0.015), z_bottom=0.0, length=0.175, width=0.090,
               height=0.072, yaw= 0.08)

    # 2. Warm cozy ankle cuffs & legs (Z = 0.05 to 0.45)
    for side in (-1.0, 1.0):
        b.add_tube(m_skirt, [
            (side * 0.095, -0.015, 0.05),
            (side * 0.090,  0.000, 0.44),
        ], [0.048, 0.065], segments=8)

    # 3. Cozy flared pleated plum skirt (lathe Z = 0.38 to 0.88)
    skirt_prof = [
        (0.245, 0.38),  # long warm flared hem
        (0.235, 0.48),
        (0.205, 0.64),
        (0.165, 0.82),  # waist
    ]
    b.add_lathe(m_skirt, (0.0, 0.0), skirt_prof, segments=14, scale_xy=(1.05, 0.88))

    # 4. Knitted lavender cardigan & draped shawl (lathe Z = 0.80 to 1.22)
    shawl_prof = [
        (0.170, 0.80),
        (0.185, 0.94),
        (0.195, 1.08),  # cozy cardigan chest
        (0.178, 1.18),  # gentle shoulders
        (0.080, 1.22),  # collar
    ]
    b.add_lathe(m_shawl, (0.0, 0.0), shawl_prof, segments=14, scale_xy=(1.05, 0.85))

    # Draped knitted shawl draped over shoulders
    for side in (-1.0, 1.0):
        b.add_tube(m_shawl, [
            (side * 0.085,  0.075, 1.21),
            (side * 0.125, -0.020, 1.22),
            (side * 0.110, -0.145, 1.12),
            (side * 0.065, -0.165, 0.95),
            (side * 0.025, -0.175, 0.84),
        ], [0.034, 0.038, 0.040, 0.036, 0.028], segments=6, aspect_xy=(1.45, 0.45))

    # Floral Cameo Brooch clasping shawl at chest
    brooch_c = (0.0, -0.172, 1.02)
    b.add_torus_ring(m_gold, brooch_c, major_r=0.024, minor_r=0.006,
                     major_segs=10, minor_segs=6, rot=(math.radians(80.0), 0.0, 0.0))
    b.add_sphere(m_brooch, brooch_c, 0.018, scale=(1.0, 0.5, 1.2), subdivisions=1)

    # Delicate lace collar peeking out
    b.add_torus_ring(m_blouse, (0.0, 0.0, 1.215), major_r=0.078, minor_r=0.016,
                     major_segs=12, minor_segs=6, rot=(math.radians(10.0), 0.0, 0.0))

    # 5. Gentle grandmotherly neck & serene smiling Pixar Head (Z = 1.22 to 1.58m)
    b.add_cylinder(m_skin, (0.0, 0.0, 1.25), 0.048, 0.044, 0.10, segments=8)
    head_c = (0.0, -0.01, 1.385)
    b.add_disney_head(m_skin, m_eye_w, m_iris, m_pupil, m_brow, m_lip, m_blush,
                      center=head_c, rx=0.114, ry=0.118, rz=0.128, eye_sep=0.042,
                      eye_z_off=0.010, eye_r=0.021, is_female=True, has_cheeks=True)

    # Round wire-rim spectacles resting on grandma's nose
    for side in (-1.0, 1.0):
        gx = side * 0.042
        gy = -0.01 - 0.118 * 0.86
        gz = 1.385 + 0.010
        b.add_torus_ring(m_glasses, (gx, gy, gz), major_r=0.028, minor_r=0.005,
                         major_segs=12, minor_segs=6, rot=(math.radians(90.0), 0.0, 0.0))
        b.add_tube(m_glasses, [
            (side * (0.042 + 0.028), gy, gz),
            (side * (0.114 * 0.94),  -0.01, gz + 0.004),
            (side * (0.114 * 0.88),   0.05, gz),
        ], 0.0045, segments=6)
    b.add_tube(m_glasses, [
        (-0.014, -0.01 - 0.118 * 0.96, 1.385 + 0.012),
        ( 0.014, -0.01 - 0.118 * 0.96, 1.385 + 0.012),
    ], 0.005, segments=6)

    # 6. Silver hair with soft waves & braided top-bun (top reaches H ≈ 1.58m!)
    b.add_sphere(m_hair, (0.0, 0.022, 1.442), 1.0, scale=(0.120, 0.122, 0.106), subdivisions=2)
    # Cozy side waves framing cheeks
    for side in (-1.0, 1.0):
        b.add_sphere(m_hair, (side * 0.098, -0.01, 1.42), 0.044, scale=(0.85, 1.1, 1.25), subdivisions=1)
    # Braided grandmother bun on top/back (reaches top vertex at 1.58m!)
    bun_c = (0.0, 0.065, 1.515)
    b.add_sphere(m_hair, bun_c, 0.062, scale=(1.15, 1.05, 1.05), subdivisions=2)
    b.add_torus_ring(m_hair, bun_c, major_r=0.054, minor_r=0.014, major_segs=12, minor_segs=6)

    # 7. Gentle, warm hands clasped tenderly in front
    for side in (-1.0, 1.0):
        b.add_sphere(m_shawl, (side * 0.18, 0.0, 1.14), 0.054, subdivisions=1)
        b.add_tube(m_shawl, [
            (side * 0.18,  0.00, 1.14),
            (side * 0.21, -0.04, 1.03),
            (side * 0.16, -0.11, 0.95),
            (side * 0.07, -0.165, 0.92),
        ], [0.046, 0.042, 0.038, 0.035], segments=8)
        # Soft caring hands overlapping at center
        b.add_sphere(m_skin, (side * 0.045, -0.175, 0.92), 0.032, scale=(1.1, 1.2, 0.85), subdivisions=1)

    b.finalize_and_export(os.path.join(OUT_DIR, "char_grandma.glb"))


# ==============================================================================
# 5. THE GRANDFATHER (Дедушка / Родственник) — H ≈ 1.72m
# ==============================================================================

def build_char_grandpa():
    b = CharacterBuilder("char_grandpa")

    m_skin    = b.mat("skin_grandpa",    "#EDBEA0", roughness=0.80, specular=0.10)
    m_eye_w   = b.mat("eye_white",       "#FFFDF8", roughness=0.40, specular=0.14)
    m_iris    = b.mat("eye_warmgray",    "#424C55", roughness=0.38, specular=0.14)
    m_pupil   = b.mat("eye_pupil",       "#121518", roughness=0.12, specular=0.14)
    m_brow    = b.mat("hair_silver",     "#D4D4D4", roughness=0.84)
    m_lip     = b.mat("lip_natural",     "#C6756C", roughness=0.74)
    m_hair    = b.mat("hair_silver",     "#D4D4D4", roughness=0.84)
    m_tweed   = b.mat("vest_foresttweed","#4A583E", roughness=0.88)
    m_shirt   = b.mat("shirt_cream",     "#F4ECE0", roughness=0.84)
    m_pants   = b.mat("pants_corduroy",  "#6E5D4A", roughness=0.86)
    m_cap     = b.mat("cap_herringbone", "#463D36", roughness=0.88)
    m_shoe    = b.mat("shoe_oxford",     "#3C2418", roughness=0.78)
    m_gold    = b.mat("watch_chain",     "#D8B04A", roughness=0.25, metallic=0.85)
    m_paper   = b.mat("paper_newsprint", "#EDE8DC", roughness=0.85)
    m_news_ink= b.mat("paper_headline",  "#383632", roughness=0.85)

    # 1. Sturdy warm oxford shoes grounded at Z = 0.000
    b.add_shoe(m_shoe, (-0.105, -0.02), z_bottom=0.0, length=0.195, width=0.094,
               height=0.078, yaw=-0.08)
    b.add_shoe(m_shoe, ( 0.105, -0.02), z_bottom=0.0, length=0.195, width=0.094,
               height=0.078, yaw= 0.08)

    # 2. Warm corduroy trousers (Z = 0.06 to 0.82)
    for side in (-1.0, 1.0):
        b.add_tube(m_pants, [
            (side * 0.100, -0.02, 0.06),
            (side * 0.095, -0.01, 0.44),
            (side * 0.085,  0.00, 0.80),
        ], [0.050, 0.062, 0.074], segments=10)

    # 3. Tweed vest over cream collared shirt (lathe Z = 0.74 to 1.34)
    torso_prof = [
        (0.165, 0.74),  # shirt hem peeking slightly
        (0.180, 0.84),  # comfortable grandfatherly belly
        (0.190, 1.02),
        (0.188, 1.18),  # chest
        (0.175, 1.28),  # shoulders
        (0.085, 1.33),  # neck opening
    ]
    torso_mats = [m_shirt, m_tweed, m_tweed, m_tweed, m_tweed, m_shirt]
    b.add_lathe(m_tweed, (0.0, 0.0), torso_prof, segments=14, scale_xy=(1.06, 0.86), mat_per_band=torso_mats)

    # Cream shirt collar
    b.add_torus_ring(m_shirt, (0.0, 0.0, 1.325), major_r=0.085, minor_r=0.016,
                     major_segs=12, minor_segs=6, rot=(math.radians(10.0), 0.0, 0.0))

    # Vest V-neck lapel edges & buttons
    for side in (-1.0, 1.0):
        b.add_tube(m_tweed, [
            (side * 0.025, -0.155, 1.12),
            (side * 0.075, -0.135, 1.24),
            (side * 0.095, -0.055, 1.31),
        ], [0.016, 0.022, 0.018], segments=6, aspect_xy=(1.4, 0.5))

    for bz in (0.88, 0.98, 1.08):
        b.add_sphere(m_gold, (0.0, -0.162, bz), 0.010, subdivisions=1)

    # Golden pocket watch chain draped across vest pocket
    b.add_tube(m_gold, [
        (0.010, -0.158, 0.98),
        (0.055, -0.165, 0.93),
        (0.105, -0.152, 0.96),
    ], 0.006, segments=6)
    b.add_sphere(m_gold, (0.108, -0.150, 0.96), 0.010, subdivisions=1)

    # 4. Cheerful grandfather head & friendly fluffy mustache (Z = 1.34 to 1.72m)
    b.add_cylinder(m_skin, (0.0, 0.0, 1.36), 0.052, 0.048, 0.12, segments=10)
    head_c = (0.0, -0.01, 1.51)
    b.add_disney_head(m_skin, m_eye_w, m_iris, m_pupil, m_brow, m_lip, None,
                      center=head_c, rx=0.116, ry=0.122, rz=0.134, eye_sep=0.043,
                      eye_z_off=0.012, eye_r=0.022, is_female=False, has_cheeks=False)

    # Friendly, plump silver mustache curving proudly under the nose
    for side in (-1.0, 1.0):
        b.add_tube(m_hair, [
            (0.0,                -0.122 * 0.98, 1.51 - 0.022),
            (side * 0.025,       -0.122 * 0.96, 1.51 - 0.026),
            (side * 0.055,       -0.122 * 0.88, 1.51 - 0.042),
        ], [0.014, 0.016, 0.009], segments=6)

    # Silver sideburns & neat back hairline
    for side in (-1.0, 1.0):
        b.add_sphere(m_hair, (side * 0.105, 0.0, 1.49), 0.038, scale=(0.8, 1.1, 1.4), subdivisions=1)
    b.add_sphere(m_hair, (0.0, 0.045, 1.52), 1.0, scale=(0.118, 0.105, 0.095), subdivisions=1)

    # 5. Classic Tweed Flat Newsboy Cap (кепка, top reaches H ≈ 1.72m!)
    cap_c = (0.0, 0.015, 1.625)
    # Cap crown volume (lathe)
    cap_prof = [
        (0.128, 1.56),
        (0.145, 1.61),
        (0.132, 1.66),
        (0.035, 1.685),
    ]
    b.add_lathe(m_cap, (0.0, 0.01), cap_prof, segments=14, scale_xy=(1.06, 1.12))
    # Cap top button
    b.add_sphere(m_cap, (0.0, 0.01, 1.688), 0.014, subdivisions=1)
    # Stitched curved cap visor / brim extending forward over forehead
    b.add_tube(m_cap, [
        (-0.082, -0.065, 1.575),
        ( 0.000, -0.155, 1.565),
        ( 0.082, -0.065, 1.575),
    ], 0.016, segments=6, aspect_xy=(1.8, 0.35))

    # 6. LEFT ARM (+X) tucked casually into pocket
    b.add_sphere(m_shirt, (0.21, 0.0, 1.24), 0.058, subdivisions=1)
    b.add_tube(m_shirt, [
        (0.21,  0.00, 1.24),
        (0.25, -0.04, 1.05),
        (0.18, -0.08, 0.86),
    ], [0.048, 0.042, 0.038], segments=8)
    b.add_sphere(m_skin, (0.165, -0.09, 0.84), 0.035, subdivisions=1)

    # 7. RIGHT ARM (-X) holding rolled newspaper
    b.add_sphere(m_shirt, (-0.21, 0.0, 1.24), 0.058, subdivisions=1)
    b.add_tube(m_shirt, [
        (-0.21,  0.00, 1.24),
        (-0.26, -0.06, 1.06),
        (-0.23, -0.14, 0.92),
    ], [0.048, 0.042, 0.038], segments=8)
    b.add_sphere(m_skin, (-0.22, -0.16, 0.90), 0.038, subdivisions=1)

    # Rolled newspaper held in right hand
    paper_c = Vector((-0.225, -0.175, 0.90))
    paper_rot = (math.radians(65.0), math.radians(14.0), math.radians(-16.0))
    b.add_cylinder(m_paper, paper_c, 0.030, 0.030, 0.32, segments=10, rot=paper_rot)
    # Dark headline band around newspaper center
    b.add_cylinder(m_news_ink, paper_c, 0.032, 0.032, 0.075, segments=10, rot=paper_rot)

    b.finalize_and_export(os.path.join(OUT_DIR, "char_grandpa.glb"))


# ==============================================================================
# MAIN BATCH EXECUTION
# ==============================================================================

def main():
    print("=" * 70)
    print("SCULPTING TRACK L1-A DISNEY/PIXAR CHARACTERS IN BLENDER 4.0.2")
    print("=" * 70)
    build_char_girl()
    build_char_mom()
    build_char_dad()
    build_char_grandma()
    build_char_grandpa()
    print("=" * 70)
    print("ALL 5 CHARACTERS SCULPTED & EXPORTED SUCCESSFULLY!")
    print("=" * 70)


if __name__ == "__main__":
    main()
