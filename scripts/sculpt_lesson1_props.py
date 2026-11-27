import bpy
import bmesh
import math
import os
from collections import deque
from mathutils import Vector, Matrix, Euler

OUT_DIR = "/home/antigravity/liprema/soulblueprint/assets/models/lesson1/props"
os.makedirs(OUT_DIR, exist_ok=True)


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_to_rgba(hex_str):
    h = hex_str.lstrip("#")
    r = srgb_to_linear(int(h[0:2], 16) / 255.0)
    g = srgb_to_linear(int(h[2:4], 16) / 255.0)
    b = srgb_to_linear(int(h[4:6], 16) / 255.0)
    return (r, g, b, 1.0)


def make_mat(name, hex_color, roughness=0.80, metallic=0.0, specular=0.12,
             emission_hex=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    mat.blend_method = 'OPAQUE'
    mat.use_backface_culling = True

    nt = mat.node_tree
    bsdf = None
    for n in nt.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            bsdf = n
            break
    if bsdf is None:
        bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')

    bsdf.inputs['Base Color'].default_value = hex_to_rgba(hex_color)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if 'Specular IOR Level' in bsdf.inputs:
        bsdf.inputs['Specular IOR Level'].default_value = specular
    elif 'Specular' in bsdf.inputs:
        bsdf.inputs['Specular'].default_value = specular

    if emission_hex is not None and emission_strength > 0.0:
        bsdf.inputs['Emission Color'].default_value = hex_to_rgba(emission_hex)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    else:
        bsdf.inputs['Emission Color'].default_value = (0.0, 0.0, 0.0, 1.0)
        bsdf.inputs['Emission Strength'].default_value = 0.0

    return mat


class PropBuilder:
    def __init__(self, name):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.name = name
        self.bm = bmesh.new()
        self.materials = []
        self.mat_map = {}

    def mat(self, name, hex_color, roughness=0.80, metallic=0.0, specular=0.12,
            emission_hex=None, emission_strength=0.0):
        if name in self.mat_map:
            return self.mat_map[name]
        m = make_mat(f"{self.name}_{name}", hex_color, roughness, metallic, specular,
                     emission_hex, emission_strength)
        idx = len(self.materials)
        self.materials.append(m)
        self.mat_map[name] = idx
        return idx

    def _tag_faces(self, faces, mat_idx, smooth=False):
        if not faces:
            return
        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        for f in faces:
            if f.is_valid:
                f.material_index = mat_idx
                f.smooth = smooth

    def add_box(self, mat_idx, center, size, rot=(0.0, 0.0, 0.0), smooth=False):
        sx, sy, sz = size
        mat_xform = (
            Matrix.Translation(Vector(center))
            @ Euler(rot, 'XYZ').to_matrix().to_4x4()
            @ Matrix.Diagonal((sx, sy, sz, 1.0))
        )
        ret = bmesh.ops.create_cube(self.bm, size=1.0, matrix=mat_xform)
        vset = set(ret['verts'])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_cylinder(self, mat_idx, center, r1, r2, depth, segments=12,
                     rot=(0.0, 0.0, 0.0), smooth=True):
        mat_xform = (
            Matrix.Translation(Vector(center))
            @ Euler(rot, 'XYZ').to_matrix().to_4x4()
        )
        ret = bmesh.ops.create_cone(
            self.bm,
            cap_ends=True,
            cap_tris=False,
            segments=segments,
            radius1=max(1e-4, r1),
            radius2=max(1e-4, r2),
            depth=depth,
            matrix=mat_xform,
        )
        vset = set(ret['verts'])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_sphere(self, mat_idx, center, radius, scale=(1.0, 1.0, 1.0),
                   subdivisions=1, smooth=True):
        mat_xform = (
            Matrix.Translation(Vector(center))
            @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
        )
        ret = bmesh.ops.create_icosphere(
            self.bm,
            subdivisions=subdivisions,
            radius=radius,
            matrix=mat_xform,
        )
        vset = set(ret['verts'])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_lathe(self, mat_idx, center_xy, profile_rz, segments=12,
                  cap_bottom=True, cap_top=True, rot_z=0.0, smooth=True):
        cx, cy = center_xy
        rings = []
        for (r, z) in profile_rz:
            rr = max(1e-4, r)
            ring = []
            for s in range(segments):
                ang = rot_z + 2.0 * math.pi * s / segments
                ring.append(self.bm.verts.new(Vector((
                    cx + rr * math.cos(ang),
                    cy + rr * math.sin(ang),
                    z,
                ))))
            rings.append(ring)

        faces = []
        for i in range(len(rings) - 1):
            r0 = rings[i]
            r1 = rings[i + 1]
            for s in range(segments):
                sn = (s + 1) % segments
                faces.append(self.bm.faces.new([r0[s], r0[sn], r1[sn], r1[s]]))
        if cap_bottom:
            faces.append(self.bm.faces.new(list(reversed(rings[0]))))
        if cap_top:
            faces.append(self.bm.faces.new(rings[-1]))
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_extruded_poly(self, mat_idx, poly_2d, thickness,
                          center=(0, 0, 0), rot=(0, 0, 0), smooth=False):
        """Extrudes a 2D polygon (in XZ plane) along Y by +/- thickness/2, then transforms."""
        half_t = thickness * 0.5
        mat_xform = (
            Matrix.Translation(Vector(center))
            @ Euler(rot, 'XYZ').to_matrix().to_4x4()
        )
        front_verts = []
        back_verts = []
        for (px, pz) in poly_2d:
            front_verts.append(self.bm.verts.new(mat_xform @ Vector((px, -half_t, pz))))
            back_verts.append(self.bm.verts.new(mat_xform @ Vector((px, +half_t, pz))))
        n = len(poly_2d)
        faces = []
        faces.append(self.bm.faces.new(front_verts))
        faces.append(self.bm.faces.new(list(reversed(back_verts))))
        for i in range(n):
            ni = (i + 1) % n
            faces.append(self.bm.faces.new([
                front_verts[i], back_verts[i], back_verts[ni], front_verts[ni]
            ]))
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def add_torus(self, mat_idx, center, major_r, minor_r, seg_major=12, seg_minor=8,
                  rot=(0, 0, 0), smooth=True):
        mat_xform = (
            Matrix.Translation(Vector(center))
            @ Euler(rot, 'XYZ').to_matrix().to_4x4()
        )
        rings = []
        for i in range(seg_major):
            theta = 2.0 * math.pi * i / seg_major
            ct, st = math.cos(theta), math.sin(theta)
            center_ring = Vector((major_r * ct, major_r * st, 0.0))
            rad_dir = Vector((ct, st, 0.0))
            up_dir = Vector((0.0, 0.0, 1.0))
            ring = []
            for j in range(seg_minor):
                phi = 2.0 * math.pi * j / seg_minor
                cp, sp = math.cos(phi), math.sin(phi)
                p = center_ring + (rad_dir * cp + up_dir * sp) * minor_r
                ring.append(self.bm.verts.new(mat_xform @ p))
            rings.append(ring)

        faces = []
        for i in range(seg_major):
            ni = (i + 1) % seg_major
            r0 = rings[i]
            r1 = rings[ni]
            for j in range(seg_minor):
                nj = (j + 1) % seg_minor
                faces.append(self.bm.faces.new([r0[j], r0[nj], r1[nj], r1[j]]))
        self._tag_faces(faces, mat_idx, smooth=smooth)
        return faces

    def verify_no_floating_parts(self, ground_tol=0.015, touch_tol=0.030):
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

    def finalize_and_export(self, filepath, center_xy=True):
        bmesh.ops.delete(
            self.bm,
            geom=[v for v in self.bm.verts if not v.link_faces],
            context='VERTS',
        )

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

        num_islands = self.verify_no_floating_parts()

        bmesh.ops.recalc_face_normals(self.bm, faces=list(self.bm.faces))
        self.bm.normal_update()

        uv_layer = self.bm.loops.layers.uv.verify()
        uv_scale = 0.5
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

        bmesh.ops.triangulate(self.bm, faces=list(self.bm.faces))

        tri_count = len(self.bm.faces)
        xs = [v.co.x for v in self.bm.verts]
        ys = [v.co.y for v in self.bm.verts]
        zs = [v.co.z for v in self.bm.verts]
        dims = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))

        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()

        for m in self.materials:
            mesh.materials.append(m)

        mesh.use_auto_smooth = True
        mesh.auto_smooth_angle = math.radians(55.0)
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
            export_apply=True,
            use_selection=True,
        )
        print(
            f"[EXPORTED] {self.name}: tris={tri_count}, islands={num_islands} (0 floating), "
            f"W={dims[0]:.2f}m, D={dims[1]:.2f}m, H={dims[2]:.2f}m -> {filepath}"
        )


# ==============================================================================
# 1. mega_skyscraper_a.glb: Modern corporate glass-and-limestone skyscraper
#    Height ~48m, footprint ~16x16m. Limestone lobby base, glass curtain wall tiers,
#    art-deco stepped crown & needle spire.
# ==============================================================================
def sculpt_skyscraper_a():
    b = PropBuilder("mega_skyscraper_a")
    
    # Palette
    c_stone = b.mat("limestone", "#D8D0C5", roughness=0.82)
    c_stone_dark = b.mat("limestone_dark", "#BAAEA0", roughness=0.85)
    c_bronze = b.mat("bronze_dark", "#2B303A", roughness=0.65, metallic=0.35)
    c_glass = b.mat("glass_curtain", "#3A5C78", roughness=0.25, metallic=0.15)
    c_glass_glow = b.mat("glass_glow", "#FDE5A4", roughness=0.20, emission_hex="#FDE5A4", emission_strength=1.8)
    c_gold = b.mat("gold_deco", "#D4AF37", roughness=0.35, metallic=0.80)
    c_beacon = b.mat("red_beacon", "#FF2222", roughness=0.20, emission_hex="#FF2222", emission_strength=3.0)

    # 1. Limestone Lobby Base (16m x 16m x 7.2m)
    # Ground slab slightly embedded to ensure solid foundation
    b.add_box(c_stone_dark, (0, 0, 0.4), (16.2, 16.2, 0.8), smooth=False)
    b.add_box(c_stone, (0, 0, 3.8), (16.0, 16.0, 6.0), smooth=False)
    
    # Lobby Cornice & Belt Course (Z=7.0m)
    b.add_box(c_stone_dark, (0, 0, 7.0), (16.4, 16.4, 0.6), smooth=False)

    # Front Entrance Portal & Recess (Front at Y = -8.0m)
    b.add_box(c_bronze, (0, -7.95, 3.2), (6.4, 0.3, 4.8), smooth=False)
    b.add_box(c_glass_glow, (0, -7.90, 2.5), (5.2, 0.2, 3.6), smooth=False) # Glowing entrance doors
    b.add_box(c_bronze, (0, -7.88, 2.5), (0.15, 0.25, 3.6), smooth=False) # Door mullion
    
    # Grand Entrance Canopy (cantilever over front entrance)
    b.add_box(c_bronze, (0, -9.6, 4.4), (7.4, 3.4, 0.35), smooth=False)
    b.add_box(c_glass_glow, (0, -9.5, 4.2), (6.8, 3.0, 0.1), smooth=False) # Canopy warm illumination
    # Canopy suspension bronze rods (anchored to facade)
    b.add_cylinder(c_bronze, (-3.2, -8.7, 5.2), 0.04, 0.04, 2.0, rot=(0.55, 0, 0))
    b.add_cylinder(c_bronze, (3.2, -8.7, 5.2), 0.04, 0.04, 2.0, rot=(0.55, 0, 0))

    # Corner rustication pilasters for lobby
    for sx in (-7.8, 7.8):
        for sy in (-7.8, 7.8):
            b.add_box(c_stone_dark, (sx, sy, 3.8), (0.9, 0.9, 6.2), smooth=False)

    # 2. Main Tower Shaft (14.8m x 14.8m, Z from 7.0m to 32.5m)
    b.add_box(c_bronze, (0, 0, 19.6), (14.8, 14.8, 25.4), smooth=False)

    # Curtain Wall Glass Panels & Limestone Vertical Piers
    # Vertical stone piers at corners and center
    for sx in (-7.1, -2.4, 2.4, 7.1):
        b.add_box(c_stone, (sx, 0, 19.6), (0.7, 14.9, 25.4), smooth=False)
    for sy in (-7.1, -2.4, 2.4, 7.1):
        b.add_box(c_stone, (0, sy, 19.6), (14.9, 0.7, 25.4), smooth=False)

    # Horizontal Spandrel Slabs (every 3.6m) and Glass Bays
    floor_zs = [10.5, 14.1, 17.7, 21.3, 24.9, 28.5, 32.0]
    for i in range(len(floor_zs) - 1):
        z_mid = (floor_zs[i] + floor_zs[i+1]) * 0.5
        # Alternating warm lit and reflective corporate glass
        mat_g = c_glass_glow if (i % 2 == 1) else c_glass
        # Glass bays on 4 facades
        b.add_box(mat_g, (0, -7.42, z_mid), (14.2, 0.15, 2.8), smooth=False)
        b.add_box(mat_g, (0, 7.42, z_mid), (14.2, 0.15, 2.8), smooth=False)
        b.add_box(mat_g, (-7.42, 0, z_mid), (0.15, 14.2, 2.8), smooth=False)
        b.add_box(mat_g, (7.42, 0, z_mid), (0.15, 14.2, 2.8), smooth=False)
        # Spandrel band
        b.add_box(c_stone_dark, (0, 0, floor_zs[i]), (15.0, 15.0, 0.6), smooth=False)
    b.add_box(c_stone_dark, (0, 0, 32.2), (15.2, 15.2, 0.8), smooth=False)

    # 3. Intermediate Setback Tier (11.6m x 11.6m, Z from 32.0m to 41.6m)
    # Penthouse terrace perimeter railing at Z=32.4m
    for sx in (-7.2, 7.2):
        b.add_box(c_bronze, (sx, 0, 32.9), (0.12, 14.6, 1.0), smooth=False)
    for sy in (-7.2, 7.2):
        b.add_box(c_bronze, (0, sy, 32.9), (14.6, 0.12, 1.0), smooth=False)

    # Tier shaft
    b.add_box(c_bronze, (0, 0, 36.8), (11.6, 11.6, 9.6), smooth=False)
    for sx in (-5.6, 0.0, 5.6):
        b.add_box(c_stone, (sx, 0, 36.8), (0.6, 11.7, 9.6), smooth=False)
    for sy in (-5.6, 0.0, 5.6):
        b.add_box(c_stone, (0, sy, 36.8), (11.7, 0.6, 9.6), smooth=False)

    # Glass bays on intermediate tier
    for tz in (34.4, 38.0):
        b.add_box(c_glass_glow, (0, -5.82, tz), (11.0, 0.12, 2.6), smooth=False)
        b.add_box(c_glass, (0, 5.82, tz), (11.0, 0.12, 2.6), smooth=False)
        b.add_box(c_glass, (-5.82, 0, tz), (0.12, 11.0, 2.6), smooth=False)
        b.add_box(c_glass_glow, (5.82, 0, tz), (0.12, 11.0, 2.6), smooth=False)

    b.add_box(c_stone_dark, (0, 0, 41.5), (12.0, 12.0, 0.6), smooth=False)

    # 4. Stepped Art-Deco Crown & Spire (Z from 41.3m to 48.0m)
    # Tier 1 (8.4m x 8.4m x 2.8m)
    b.add_box(c_stone, (0, 0, 42.8), (8.4, 8.4, 2.8), smooth=False)
    b.add_box(c_gold, (0, 0, 43.6), (8.6, 8.6, 0.35), smooth=False)

    # Tier 2 (5.8m x 5.8m x 2.0m)
    b.add_box(c_stone_dark, (0, 0, 45.0), (5.8, 5.8, 2.0), smooth=False)
    b.add_box(c_gold, (0, 0, 45.6), (6.0, 6.0, 0.3), smooth=False)

    # Tier 3 (3.6m x 3.6m x 1.2m)
    b.add_box(c_stone, (0, 0, 46.4), (3.6, 3.6, 1.2), smooth=False)

    # Art-Deco Spire Base & Needle Spire reaching 48.2m
    b.add_cylinder(c_gold, (0, 0, 47.1), 1.5, 0.6, 0.8, segments=8, smooth=False)
    b.add_cylinder(c_gold, (0, 0, 47.7), 0.5, 0.08, 0.8, segments=8, smooth=False)
    # Top needle and beacon
    b.add_cylinder(c_bronze, (0, 0, 48.1), 0.07, 0.03, 0.5, segments=6, smooth=False)
    b.add_sphere(c_beacon, (0, 0, 48.3), 0.12, subdivisions=1, smooth=True)

    b.finalize_and_export(os.path.join(OUT_DIR, "mega_skyscraper_a.glb"))


# ==============================================================================
# 2. mega_skyscraper_b.glb: Stepped modern metropolis tower
#    Height ~38m, footprint ~14x14m. Tiered facade with penthouse terraces,
#    railings, rooftop antennae, contrasting matte panels.
# ==============================================================================
def sculpt_skyscraper_b():
    b = PropBuilder("mega_skyscraper_b")

    # Palette
    c_podium = b.mat("dark_podium", "#323842", roughness=0.85)
    c_white_panel = b.mat("matte_concrete", "#E2DDD5", roughness=0.80)
    c_slate_panel = b.mat("matte_slate", "#48505C", roughness=0.78)
    c_terracotta = b.mat("terracotta_trim", "#B85848", roughness=0.75)
    c_dark_mullion = b.mat("dark_mullion", "#252A32", roughness=0.70, metallic=0.3)
    c_glass = b.mat("window_glass", "#3A556B", roughness=0.30, metallic=0.10)
    c_glass_glow = b.mat("window_glow", "#FDE8AB", roughness=0.20, emission_hex="#FDE8AB", emission_strength=1.8)
    c_metal = b.mat("galvanized_steel", "#8A94A0", roughness=0.45, metallic=0.75)
    c_foliage = b.mat("terrace_shrub", "#3A6E48", roughness=0.82)
    c_beacon = b.mat("red_beacon", "#FF2222", roughness=0.20, emission_hex="#FF2222", emission_strength=3.0)

    # 1. Base Podium Tier (14.0m x 14.0m x 8.0m)
    b.add_box(c_podium, (0, 0, 4.0), (14.0, 14.0, 8.0), smooth=False)
    # Base entrance canopy & illuminated lobby
    b.add_box(c_glass_glow, (0, -6.95, 2.5), (6.0, 0.25, 3.8), smooth=False)
    b.add_box(c_slate_panel, (0, -8.0, 4.6), (7.2, 2.6, 0.35), smooth=False)
    # Accent louvers on base podium
    for lz in (2.0, 3.5, 5.0, 6.5):
        b.add_box(c_terracotta, (0, 6.95, lz), (13.6, 0.25, 0.25), smooth=False)
        b.add_box(c_terracotta, (-6.95, 0, lz), (0.25, 13.6, 0.25), smooth=False)
        b.add_box(c_terracotta, (6.95, 0, lz), (0.25, 13.6, 0.25), smooth=False)

    # Podium cornice slab at Z=8.0m
    b.add_box(c_slate_panel, (0, 0, 8.0), (14.4, 14.4, 0.6), smooth=False)

    # 2. Main Mid Tier (12.2m x 12.2m, Z from 7.8m to 20.0m)
    b.add_box(c_white_panel, (0, 0, 13.9), (12.2, 12.2, 12.0), smooth=False)

    # Contrasting vertical slate & terracotta feature stripes
    for sx in (-5.8, 5.8):
        b.add_box(c_terracotta, (sx, 0, 13.9), (0.5, 12.3, 12.0), smooth=False)
    for sy in (-5.8, 5.8):
        b.add_box(c_slate_panel, (0, sy, 13.9), (12.3, 0.5, 12.0), smooth=False)

    # Window grids across Mid Tier
    for wz in (10.5, 13.5, 16.5):
        mat_w = c_glass_glow if (wz == 13.5) else c_glass
        b.add_box(mat_w, (0, -6.12, wz), (11.0, 0.12, 1.8), smooth=False)
        b.add_box(mat_w, (0, 6.12, wz), (11.0, 0.12, 1.8), smooth=False)
        b.add_box(mat_w, (-6.12, 0, wz), (0.12, 11.0, 1.8), smooth=False)
        b.add_box(mat_w, (6.12, 0, wz), (0.12, 11.0, 1.8), smooth=False)
        # Mullions
        for mx in (-3.6, 0, 3.6):
            b.add_box(c_dark_mullion, (mx, -6.14, wz), (0.2, 0.18, 1.8), smooth=False)
            b.add_box(c_dark_mullion, (mx, 6.14, wz), (0.2, 0.18, 1.8), smooth=False)

    # Belt cornice slab at Z=20.0m
    b.add_box(c_slate_panel, (0, 0, 20.0), (12.5, 12.5, 0.6), smooth=False)

    # 3. Upper Penthouse Tier with Asymmetric Setback Terrace (9.4m x 9.4m, Z from 19.8m to 30.0m)
    # Terrace at Z=20.2m: Railings around the exposed perimeter (from 9.4m to 12.2m)
    for sx in (-5.9, 5.9):
        b.add_box(c_dark_mullion, (sx, 0, 20.8), (0.08, 11.8, 1.0), smooth=False)
    for sy in (-5.9, 5.9):
        b.add_box(c_dark_mullion, (0, sy, 20.8), (11.8, 0.08, 1.0), smooth=False)
    # Terrace planters with manicured shrubs
    for px, py in ((-5.0, -5.0), (5.0, -5.0), (-5.0, 5.0), (5.0, 5.0)):
        b.add_box(c_terracotta, (px, py, 20.5), (0.9, 0.9, 0.6), smooth=False)
        b.add_sphere(c_foliage, (px, py, 21.0), 0.55, subdivisions=1, smooth=True)

    # Penthouse shaft (9.4m x 9.4m)
    b.add_box(c_slate_panel, (0, 0, 24.9), (9.4, 9.4, 9.8), smooth=False)
    # Wide panoramic penthouse glazing
    for pz in (23.0, 26.5):
        b.add_box(c_glass_glow, (0, -4.72, pz), (8.6, 0.12, 2.2), smooth=False)
        b.add_box(c_glass, (0, 4.72, pz), (8.6, 0.12, 2.2), smooth=False)
        b.add_box(c_glass, (-4.72, 0, pz), (0.12, 8.6, 2.2), smooth=False)
        b.add_box(c_glass_glow, (4.72, 0, pz), (0.12, 8.6, 2.2), smooth=False)

    b.add_box(c_white_panel, (0, 0, 29.8), (9.8, 9.8, 0.6), smooth=False)

    # 4. Rooftop Utility & Antenna Deck (6.8m x 6.8m, Z from 29.6m to 35.0m)
    b.add_box(c_podium, (0, 0, 32.4), (6.8, 6.8, 5.0), smooth=False)
    # Cantilever roof slab
    b.add_box(c_slate_panel, (0, 0, 35.0), (7.4, 7.4, 0.5), smooth=False)

    # Rooftop HVAC chillers & maintenance equipment (Z=35.2m to 36.6m)
    b.add_box(c_slate_panel, (-1.8, 1.2, 35.8), (2.2, 1.6, 1.2), smooth=False)
    b.add_box(c_dark_mullion, (-1.8, 1.2, 36.3), (1.8, 1.4, 0.3), smooth=False) # Fan grill
    b.add_cylinder(c_dark_mullion, (-1.8, 1.2, 36.5), 0.45, 0.45, 0.25, segments=8) # Chiller fan ring

    # Satellite Dish (Z from 35.0m to 37.0m)
    b.add_cylinder(c_metal, (1.8, -1.6, 35.6), 0.08, 0.08, 1.2, segments=6) # Mount post
    dish_profile = [(0.05, 36.0), (0.45, 36.2), (0.85, 36.6), (0.90, 36.7)]
    b.add_lathe(c_white_panel, (1.8, -1.6), dish_profile, segments=12, smooth=True)
    b.add_sphere(c_metal, (1.8, -1.6, 36.4), 0.12, subdivisions=1) # LNB feed

    # Communication Antenna Mast reaching ~38.2m
    b.add_cylinder(c_metal, (0, 0, 36.0), 0.28, 0.28, 2.0, segments=8)
    b.add_cylinder(c_metal, (0, 0, 37.0), 0.16, 0.08, 2.2, segments=8)
    b.add_cylinder(c_metal, (0, 0, 38.0), 0.06, 0.02, 1.2, segments=6)
    b.add_sphere(c_beacon, (0, 0, 38.25), 0.12, subdivisions=1, smooth=True)

    b.finalize_and_export(os.path.join(OUT_DIR, "mega_skyscraper_b.glb"))


# ==============================================================================
# 3. mega_family_house.glb: Cozy upscale family townhouse / villa
#    Height ~10.5m, footprint ~11x12m. Gabled roofs with shingles, brick chimney,
#    welcoming entrance porch with stone steps, large bay windows with warm glow.
# ==============================================================================
def sculpt_family_house():
    b = PropBuilder("mega_family_house")

    # Palette
    c_stone = b.mat("stone_foundation", "#8C8578", roughness=0.88)
    c_siding = b.mat("warm_siding", "#EFE5D5", roughness=0.82)
    c_trim = b.mat("white_trim", "#FAF6EE", roughness=0.75)
    c_shingle = b.mat("terracotta_shingles", "#96483B", roughness=0.80)
    c_chimney = b.mat("red_brick", "#A64536", roughness=0.85)
    c_chimney_cap = b.mat("chimney_concrete", "#C5BFB4", roughness=0.80)
    c_door = b.mat("dark_timber", "#56321F", roughness=0.72)
    c_shutters = b.mat("sage_shutters", "#4A6B5B", roughness=0.75)
    c_window_glow = b.mat("warm_glow", "#FFE49E", roughness=0.20, emission_hex="#FFE49E", emission_strength=1.8)
    c_bronze = b.mat("brass_hardware", "#C99E3D", roughness=0.35, metallic=0.75)
    c_lantern = b.mat("lantern_glow", "#FFD070", roughness=0.20, emission_hex="#FFD070", emission_strength=2.2)

    # 1. Foundation Plinth (11.2m x 12.2m x 0.8m)
    b.add_box(c_stone, (0, 0, 0.4), (11.2, 12.2, 0.8), smooth=False)

    # 2. Main Two-Story Body (10.4m x 11.4m, Z from 0.75m to 6.2m)
    b.add_box(c_siding, (0, 0, 3.48), (10.4, 11.4, 5.5), smooth=False)

    # White corner boards and belt courses
    for sx in (-5.15, 5.15):
        for sy in (-5.65, 5.65):
            b.add_box(c_trim, (sx, sy, 3.48), (0.35, 0.35, 5.5), smooth=False)
    b.add_box(c_trim, (0, 0, 3.6), (10.5, 11.5, 0.22), smooth=False) # Mid belt
    b.add_box(c_trim, (0, 0, 6.2), (10.6, 11.6, 0.30), smooth=False) # Eave band

    # 3. Welcoming Front Porch (Front at Y = -5.7m, width 4.8m, depth 2.4m, Z from 0.0 to 3.8m)
    # Porch stone steps
    for step_i, sz in enumerate((0.24, 0.48, 0.72)):
        sy = -6.8 - 0.35 * (2 - step_i)
        b.add_box(c_stone, (0, sy, sz * 0.5), (3.6 + step_i * 0.4, 0.4, sz), smooth=False)

    # Porch deck at Z=0.75m
    b.add_box(c_door, (0, -6.8, 0.75), (4.6, 2.4, 0.15), smooth=False)

    # 4 Tuscan Wooden Porch Columns (Z from 0.75m to 3.4m)
    for px in (-2.0, 2.0):
        for py in (-7.8, -5.9):
            b.add_box(c_trim, (px, py, 0.9), (0.32, 0.32, 0.3), smooth=False) # Column base
            b.add_cylinder(c_trim, (px, py, 2.1), 0.11, 0.10, 2.2, segments=10) # Column shaft
            b.add_box(c_trim, (px, py, 3.3), (0.32, 0.32, 0.2), smooth=False) # Column capital

    # Porch Balustrades / Railings
    b.add_box(c_trim, (-2.0, -6.85, 1.55), (0.1, 1.7, 0.08), smooth=False) # Left handrail
    b.add_box(c_trim, (2.0, -6.85, 1.55), (0.1, 1.7, 0.08), smooth=False) # Right handrail
    for ry in (-7.4, -7.0, -6.6, -6.2):
        b.add_cylinder(c_trim, (-2.0, ry, 1.15), 0.03, 0.03, 0.75, segments=6)
        b.add_cylinder(c_trim, (2.0, ry, 1.15), 0.03, 0.03, 0.75, segments=6)

    # Porch Gabled Roof
    porch_poly = [(-2.5, 3.3), (0.0, 4.4), (2.5, 3.3)]
    b.add_extruded_poly(c_shingle, porch_poly, thickness=2.6, center=(0, -6.8, 0), rot=(0, 0, 0))
    b.add_box(c_trim, (0, -6.8, 3.4), (4.8, 2.5, 0.18), smooth=False)

    # Front Door & Warm Carriage Lantern
    b.add_box(c_door, (0, -5.72, 2.1), (1.4, 0.15, 2.5), smooth=False)
    b.add_box(c_bronze, (0.45, -5.82, 2.0), (0.06, 0.08, 0.15), smooth=False) # Handle
    b.add_sphere(c_lantern, (1.1, -5.85, 2.6), 0.14, subdivisions=1, smooth=True) # Porch light

    # 4. Large Two-Story Bay Window (Front Facade at X = 2.6m, Z from 0.8m to 5.8m)
    # Projects out by 0.75m
    b.add_box(c_trim, (2.6, -5.95, 3.4), (2.8, 1.2, 4.8), smooth=False)
    # Bay window glowing glass panes
    b.add_box(c_window_glow, (2.6, -6.52, 2.3), (2.2, 0.12, 1.8), smooth=False) # Lower bay glass
    b.add_box(c_window_glow, (2.6, -6.52, 4.5), (2.2, 0.12, 1.8), smooth=False) # Upper bay glass
    # Bay window rooflet
    bay_roof_poly = [(-1.5, 5.7), (0.0, 6.3), (1.5, 5.7)]
    b.add_extruded_poly(c_shingle, bay_roof_poly, thickness=1.4, center=(2.6, -5.95, 0), rot=(0, 0, 0))

    # Additional Cozy Windows with Sage Shutters
    # First floor left window
    b.add_box(c_window_glow, (-2.8, -5.72, 2.3), (1.6, 0.12, 1.6), smooth=False)
    b.add_box(c_shutters, (-3.8, -5.74, 2.3), (0.4, 0.10, 1.6), smooth=False)
    b.add_box(c_shutters, (-1.8, -5.74, 2.3), (0.4, 0.10, 1.6), smooth=False)

    # Second floor windows
    b.add_box(c_window_glow, (-2.8, -5.72, 4.5), (1.6, 0.12, 1.6), smooth=False)
    b.add_box(c_shutters, (-3.8, -5.74, 4.5), (0.4, 0.10, 1.6), smooth=False)
    b.add_box(c_shutters, (-1.8, -5.74, 4.5), (0.4, 0.10, 1.6), smooth=False)

    # Side glowing windows
    for wy in (-2.5, 2.5):
        b.add_box(c_window_glow, (-5.22, wy, 2.3), (0.12, 1.5, 1.5), smooth=False)
        b.add_box(c_window_glow, (-5.22, wy, 4.5), (0.12, 1.5, 1.5), smooth=False)
        b.add_box(c_window_glow, (5.22, wy, 2.3), (0.12, 1.5, 1.5), smooth=False)
        b.add_box(c_window_glow, (5.22, wy, 4.5), (0.12, 1.5, 1.5), smooth=False)

    # 5. Steep Gabled Roof with Shingles (Z from 6.0m to 9.5m)
    # Main roof gable along Y axis (ridge from Y=-6.0 to +6.0)
    roof_poly = [(-5.6, 6.0), (0.0, 9.5), (5.6, 6.0)]
    b.add_extruded_poly(c_shingle, roof_poly, thickness=12.2, center=(0, 0, 0), rot=(0, 0, 0))
    # Eave trim fascia
    b.add_box(c_trim, (0, 0, 6.05), (11.0, 12.0, 0.25), smooth=False)

    # 6. Charming Attic Dormer Window (Front slope, center-left at X = -2.2m)
    dormer_poly = [(-1.3, 7.3), (0.0, 8.8), (1.3, 7.3)]
    b.add_extruded_poly(c_shingle, dormer_poly, thickness=2.2, center=(-2.2, -4.6, 0), rot=(0, 0, 0))
    b.add_box(c_trim, (-2.2, -4.6, 7.3), (2.3, 2.0, 1.6), smooth=False) # Dormer walls
    b.add_box(c_window_glow, (-2.2, -5.62, 7.5), (1.2, 0.12, 1.2), smooth=False) # Arched glowing dormer window

    # 7. Traditional Red Brick Chimney rising to 10.5m (Side wall at X = 5.2m, Y = 0.5m)
    b.add_box(c_chimney, (5.2, 0.5, 5.2), (1.4, 1.8, 9.6), smooth=False)
    # Chimney decorative brick corbel near top (Z=9.8m)
    b.add_box(c_chimney, (5.2, 0.5, 9.9), (1.55, 1.95, 0.35), smooth=False)
    # Chimney concrete cap (Z=10.1m)
    b.add_box(c_chimney_cap, (5.2, 0.5, 10.15), (1.65, 2.05, 0.2), smooth=False)
    # 2 Flared Terracotta Chimney Pots reaching 10.5m
    b.add_cylinder(c_shingle, (5.2, 0.0, 10.4), 0.22, 0.26, 0.45, segments=8)
    b.add_cylinder(c_shingle, (5.2, 1.0, 10.4), 0.22, 0.26, 0.45, segments=8)

    b.finalize_and_export(os.path.join(OUT_DIR, "mega_family_house.glb"))


# ==============================================================================
# 4. prop_birthday_table.glb: Iconic Birthday Table («Было всё, кроме времени»)
#    Height ~1.25m, width ~2.2m. Round wooden table, flowing ivory tablecloth,
#    multi-tiered pastel cake with 7 candles, luxury gift boxes with satin bows,
#    party hats, empty wooden chairs around. Grounded at Y_min = 0.0000.
# ==============================================================================
def sculpt_birthday_table():
    b = PropBuilder("prop_birthday_table")

    # Palette
    c_wood = b.mat("cherry_wood", "#4A2213", roughness=0.68)
    c_cloth = b.mat("ivory_cloth", "#F7F3E9", roughness=0.82)
    c_gold_ribbon = b.mat("gold_ribbon", "#DCAE38", roughness=0.35, metallic=0.75)
    c_cake_mint = b.mat("cake_mint", "#9ED4D4", roughness=0.70)
    c_cake_lavender = b.mat("cake_lavender", "#CEBCE6", roughness=0.70)
    c_cake_pink = b.mat("cake_pink", "#F4ADC0", roughness=0.70)
    c_frosting = b.mat("white_frosting", "#FFFFF8", roughness=0.60)
    c_candle = b.mat("candle_spiral", "#FFE066", roughness=0.50)
    c_flame = b.mat("candle_flame", "#FFA020", roughness=0.20, emission_hex="#FFA020", emission_strength=3.5)
    
    # Festive gift wraps
    c_gift_blue = b.mat("gift_sapphire", "#2A5885", roughness=0.55)
    c_gift_coral = b.mat("gift_coral", "#DE5862", roughness=0.55)
    c_gift_yellow = b.mat("gift_yellow", "#F0B630", roughness=0.55)
    c_gift_teal = b.mat("gift_teal", "#288270", roughness=0.55)
    c_ribbon_cyan = b.mat("ribbon_cyan", "#4DC4C4", roughness=0.40)
    c_ribbon_purple = b.mat("ribbon_purple", "#7E4296", roughness=0.40)
    c_ribbon_white = b.mat("ribbon_silver", "#E8ECEE", roughness=0.35, metallic=0.3)

    # 1. Round Wooden Table & Pedestal Base
    # 4 Carved Wooden Table Legs grounded at Z=0.0000
    for ang in (0.0, 0.5 * math.pi, math.pi, 1.5 * math.pi):
        ca, sa = math.cos(ang), math.sin(ang)
        # S-curved leg sweeping down to floor
        b.add_box(c_wood, (0.42 * ca, 0.42 * sa, 0.12), (0.12, 0.12, 0.22), rot=(0, 0, ang), smooth=False)
        b.add_cylinder(c_wood, (0.55 * ca, 0.55 * sa, 0.05), 0.07, 0.09, 0.10, rot=(0, 0, ang))
    
    # Central Turned Baluster Pedestal
    table_pedestal_profile = [
        (0.24, 0.08), (0.16, 0.22), (0.10, 0.38), (0.14, 0.52), (0.20, 0.65), (0.35, 0.72)
    ]
    b.add_lathe(c_wood, (0, 0), table_pedestal_profile, segments=12, smooth=True)

    # Tabletop wood disc (diameter 1.6m, thickness 0.04m, Z=0.74m)
    b.add_cylinder(c_wood, (0, 0, 0.73), 0.80, 0.80, 0.04, segments=20)

    # 2. Draped Flowing Ivory Tablecloth (diameter 1.68m, flowing skirts down to Z=0.38m)
    b.add_cylinder(c_cloth, (0, 0, 0.755), 0.84, 0.84, 0.02, segments=20)
    cloth_profile = [
        (0.85, 0.75), (0.87, 0.68), (0.85, 0.55), (0.88, 0.42), (0.84, 0.38)
    ]
    b.add_lathe(c_cloth, (0, 0), cloth_profile, segments=20, smooth=True)
    # Gold hem border along bottom of tablecloth
    b.add_cylinder(c_gold_ribbon, (0, 0, 0.385), 0.855, 0.855, 0.025, segments=20)

    # 3. Multi-Tiered Pastel Birthday Cake (center of table, Z from 0.76m to 1.14m)
    # Cake gold display platter
    b.add_cylinder(c_gold_ribbon, (0, 0, 0.77), 0.25, 0.25, 0.02, segments=16)
    # Tier 1 (Mint pastel)
    b.add_cylinder(c_cake_mint, (0, 0, 0.83), 0.22, 0.22, 0.10, segments=16)
    b.add_torus(c_frosting, (0, 0, 0.88), 0.22, 0.016, seg_major=16, seg_minor=8) # Pearl cream beads
    # Tier 2 (Lavender pastel)
    b.add_cylinder(c_cake_lavender, (0, 0, 0.925), 0.16, 0.16, 0.09, segments=16)
    b.add_torus(c_frosting, (0, 0, 0.97), 0.16, 0.014, seg_major=16, seg_minor=8)
    # Tier 3 (Pink pastel)
    b.add_cylinder(c_cake_pink, (0, 0, 1.01), 0.10, 0.10, 0.08, segments=16)
    b.add_torus(c_frosting, (0, 0, 1.05), 0.10, 0.012, seg_major=16, seg_minor=8)

    # 7 Festive Birthday Candles with Glowing Flames
    # 6 in a circle (radius 0.06m) + 1 in center
    candle_pts = [(0, 0)] + [
        (0.06 * math.cos(i * math.pi / 3.0), 0.06 * math.sin(i * math.pi / 3.0))
        for i in range(6)
    ]
    for cx, cy in candle_pts:
        b.add_cylinder(c_candle, (cx, cy, 1.09), 0.008, 0.008, 0.07, segments=6)
        b.add_sphere(c_flame, (cx, cy, 1.135), 0.014, scale=(0.8, 0.8, 1.5), subdivisions=1, smooth=True)

    # 4. Festive Wrapped Luxury Gift Boxes with Colorful Satin Ribbons and Bows
    # Box 1: Large royal sapphire gift box with gold ribbon
    b.add_box(c_gift_blue, (-0.36, 0.28, 0.89), (0.32, 0.32, 0.26), rot=(0, 0, 0.25), smooth=False)
    b.add_box(c_gold_ribbon, (-0.36, 0.28, 0.89), (0.33, 0.06, 0.262), rot=(0, 0, 0.25), smooth=False)
    b.add_box(c_gold_ribbon, (-0.36, 0.28, 0.89), (0.06, 0.33, 0.262), rot=(0, 0, 0.25), smooth=False)
    # 3D Gold Ribbon Bow loops
    b.add_torus(c_gold_ribbon, (-0.36, 0.28, 1.03), 0.055, 0.018, seg_major=8, seg_minor=6, rot=(0.4, 0.2, 0.25))
    b.add_torus(c_gold_ribbon, (-0.36, 0.28, 1.03), 0.055, 0.018, seg_major=8, seg_minor=6, rot=(-0.4, -0.2, 0.25))

    # Box 2: Coral-red rectangular gift box with mint ribbon
    b.add_box(c_gift_coral, (0.35, 0.25, 0.85), (0.34, 0.24, 0.18), rot=(0, 0, -0.35), smooth=False)
    b.add_box(c_ribbon_cyan, (0.35, 0.25, 0.85), (0.35, 0.05, 0.182), rot=(0, 0, -0.35), smooth=False)
    b.add_torus(c_ribbon_cyan, (0.35, 0.25, 0.95), 0.045, 0.015, seg_major=8, seg_minor=6, rot=(0.3, 0, -0.35))

    # Box 3: Cylindrical hatbox in bright yellow with purple ribbon
    b.add_cylinder(c_gift_yellow, (-0.32, -0.28, 0.86), 0.14, 0.14, 0.20, segments=12)
    b.add_torus(c_ribbon_purple, (-0.32, -0.28, 0.88), 0.142, 0.016, seg_major=12, seg_minor=6)
    b.add_torus(c_ribbon_purple, (-0.32, -0.28, 0.97), 0.045, 0.015, seg_major=8, seg_minor=6)

    # Box 4: Small luxury jewelry box in emerald teal with silver ribbon
    b.add_box(c_gift_teal, (0.30, -0.30, 0.82), (0.18, 0.18, 0.12), rot=(0, 0, 0.4), smooth=False)
    b.add_box(c_ribbon_white, (0.30, -0.30, 0.82), (0.19, 0.04, 0.122), rot=(0, 0, 0.4), smooth=False)
    b.add_torus(c_ribbon_white, (0.30, -0.30, 0.89), 0.035, 0.012, seg_major=8, seg_minor=6)

    # 5. Colorful Cone Party Hats on the Table
    for hx, hy, hc, hr in ((-0.05, -0.42, c_gift_coral, c_gift_yellow),
                           (0.12, 0.46, c_gift_teal, c_gift_coral),
                           (-0.48, 0.02, c_gift_yellow, c_gift_blue)):
        b.add_cylinder(hc, (hx, hy, 0.83), 0.07, 0.005, 0.15, segments=10)
        b.add_sphere(hr, (hx, hy, 0.91), 0.02, subdivisions=1, smooth=True) # Pom-pom

    # 6. Empty Wooden Chairs Around the Table (at angles -120°, 0°, +120° at radius 1.05m)
    # Symbolizing absent parents («Было всё, кроме времени»)
    for chair_ang in (-2.0 * math.pi / 3.0, 0.0, 2.0 * math.pi / 3.0):
        # Chair faces toward table center
        ca, sa = math.cos(chair_ang), math.sin(chair_ang)
        chair_cx, chair_cy = 1.05 * ca, 1.05 * sa
        rot_chair = (0.0, 0.0, chair_ang + math.pi)

        # 4 Turned legs grounded on floor Z=0.0000
        for lx, ly in ((-0.18, -0.18), (0.18, -0.18), (-0.18, 0.18), (0.18, 0.18)):
            # Local to world
            mat_chair = Matrix.Translation(Vector((chair_cx, chair_cy, 0))) @ Euler(rot_chair, 'XYZ').to_matrix().to_4x4()
            leg_pt = mat_chair @ Vector((lx, ly, 0.22))
            b.add_cylinder(c_wood, (leg_pt.x, leg_pt.y, 0.22), 0.025, 0.02, 0.44, segments=6)

        # Chair seat (at Z=0.45m)
        seat_pos = Vector((chair_cx, chair_cy, 0.45))
        b.add_box(c_wood, (seat_pos.x, seat_pos.y, seat_pos.z), (0.44, 0.44, 0.04), rot=rot_chair, smooth=False)

        # Chair Spindle Backrest (rising to Z=0.95m)
        back_upright_l = mat_chair @ Vector((-0.18, -0.18, 0.70))
        back_upright_r = mat_chair @ Vector((0.18, -0.18, 0.70))
        b.add_cylinder(c_wood, (back_upright_l.x, back_upright_l.y, 0.70), 0.022, 0.022, 0.48, segments=6)
        b.add_cylinder(c_wood, (back_upright_r.x, back_upright_r.y, 0.70), 0.022, 0.022, 0.48, segments=6)
        # Center spindles
        for sx in (-0.09, 0.0, 0.09):
            spindle_pt = mat_chair @ Vector((sx, -0.18, 0.68))
            b.add_cylinder(c_wood, (spindle_pt.x, spindle_pt.y, 0.68), 0.014, 0.014, 0.44, segments=6)
        # Top crest rail
        crest_pos = mat_chair @ Vector((0.0, -0.18, 0.94))
        b.add_box(c_wood, (crest_pos.x, crest_pos.y, crest_pos.z), (0.46, 0.05, 0.06), rot=rot_chair, smooth=False)

    b.finalize_and_export(os.path.join(OUT_DIR, "prop_birthday_table.glb"))


# ==============================================================================
# 5. prop_city_car.glb: Stylized Pixar city sedan / taxi
#    Length ~3.8m, width ~1.7m, height ~1.42m. Rounded charming Pixar proportions,
#    front grill, cute headlights, bumper, tires with rims, windshield, side mirrors.
#    Grounded at Y_min = 0.0000.
# ==============================================================================
def sculpt_city_car():
    b = PropBuilder("prop_city_car")

    # Palette
    c_taxi_yellow = b.mat("taxi_yellow", "#EAA218", roughness=0.55, specular=0.15)
    c_dark_chassis = b.mat("dark_chassis", "#222428", roughness=0.85)
    c_chrome = b.mat("chrome_trim", "#D8DFE5", roughness=0.25, metallic=0.82)
    c_rubber = b.mat("tire_rubber", "#2A2B2D", roughness=0.84)
    c_glass = b.mat("tinted_windshield", "#2E3F50", roughness=0.25, metallic=0.10)
    c_headlight = b.mat("glowing_headlight", "#FFF4D4", roughness=0.20, emission_hex="#FFF4D4", emission_strength=2.2)
    c_taillight_red = b.mat("red_taillight", "#D42020", roughness=0.20, emission_hex="#D42020", emission_strength=2.0)
    c_amber_light = b.mat("amber_indicator", "#F08C18", roughness=0.20, emission_hex="#F08C18", emission_strength=1.8)
    c_taxi_roof = b.mat("taxi_roof_sign", "#FFF2B0", roughness=0.25, emission_hex="#FFF2B0", emission_strength=1.6)

    # Car orientation: Along Y axis. Length 3.8m (Y from -1.9m to +1.9m), Width 1.7m (X from -0.85m to +0.85m)
    # Wheel radius = 0.31m. Center of wheel axle at Z = 0.31m.
    # Lowest point of tires is at EXACTLY Z = 0.0000.

    # 1. Wheels & Tires (4 wheels: front at Y=+1.10m, rear at Y=-1.10m, X = +/-0.72m, Z=0.31m)
    for wx in (-0.72, 0.72):
        for wy in (-1.10, 1.10):
            # Chunky rounded Pixar tire (cylinder oriented along X axis)
            b.add_cylinder(c_rubber, (wx, wy, 0.31), 0.31, 0.31, 0.22, segments=16, rot=(0, 0.5 * math.pi, 0))
            # Chrome hubcap on outer side
            sign_x = 1.0 if wx > 0 else -1.0
            hub_x = wx + sign_x * 0.10
            b.add_cylinder(c_chrome, (hub_x, wy, 0.31), 0.20, 0.20, 0.04, segments=12, rot=(0, 0.5 * math.pi, 0))
            b.add_sphere(c_chrome, (hub_x + sign_x * 0.02, wy, 0.31), 0.08, scale=(0.5, 1.0, 1.0), subdivisions=1, smooth=True)

    # 2. Undercarriage & Axles (Z=0.31m, solidly connecting wheels to body)
    b.add_box(c_dark_chassis, (0, 0, 0.32), (1.30, 3.20, 0.22), smooth=False)
    b.add_cylinder(c_dark_chassis, (0, 1.10, 0.31), 0.06, 0.06, 1.40, segments=8, rot=(0, 0.5 * math.pi, 0))
    b.add_cylinder(c_dark_chassis, (0, -1.10, 0.31), 0.06, 0.06, 1.40, segments=8, rot=(0, 0.5 * math.pi, 0))

    # 3. Main Charming Body Shell (Z from 0.28m to 0.88m)
    # Lower chassis body
    b.add_box(c_taxi_yellow, (0, 0, 0.58), (1.56, 3.65, 0.44), smooth=False)
    # Front rounded hood (Y from +0.5m to +1.8m)
    b.add_box(c_taxi_yellow, (0, 1.15, 0.68), (1.50, 1.35, 0.30), smooth=False)
    # Rear rounded trunk (Y from -0.6m to -1.8m)
    b.add_box(c_taxi_yellow, (0, -1.20, 0.66), (1.50, 1.25, 0.28), smooth=False)
    # Chrome rocker side trim
    for sx in (-0.79, 0.79):
        b.add_box(c_chrome, (sx, 0, 0.38), (0.04, 3.40, 0.06), smooth=False)

    # 4. Cabin & Rounded Greenhouse (Z from 0.82m to 1.42m, Y from -0.75m to +0.85m)
    # Cabin body shell
    b.add_box(c_taxi_yellow, (0, 0.05, 1.12), (1.36, 1.95, 0.54), smooth=False)

    # Windshield (front angled glass pane at Y = +0.92m, Z from 0.88m to 1.36m)
    b.add_box(c_glass, (0, 0.95, 1.10), (1.30, 0.12, 0.48), rot=(-0.35, 0, 0), smooth=False)
    # Rear window (angled back at Y = -0.85m)
    b.add_box(c_glass, (0, -0.86, 1.10), (1.30, 0.12, 0.46), rot=(0.32, 0, 0), smooth=False)
    # Side passenger windows
    for sx in (-0.69, 0.69):
        b.add_box(c_glass, (sx, 0.08, 1.12), (0.08, 1.60, 0.42), smooth=False)
        # Center door B-pillar
        b.add_box(c_taxi_yellow, (sx, 0.08, 1.12), (0.10, 0.12, 0.44), smooth=False)

    # Curved roof panel
    b.add_box(c_taxi_yellow, (0, 0.05, 1.39), (1.32, 1.80, 0.08), smooth=False)

    # Taxi Roof Sign Pod (Z from 1.40m to 1.54m)
    b.add_box(c_taxi_roof, (0, 0.05, 1.47), (0.48, 0.22, 0.14), smooth=False)
    b.add_box(c_chrome, (0, 0.05, 1.41), (0.52, 0.26, 0.04), smooth=False)

    # 5. Front Face: Grille, Headlights, Bumper
    # Front Chrome Bumper at Y = +1.88m, Z = 0.38m
    b.add_box(c_chrome, (0, 1.88, 0.38), (1.58, 0.12, 0.14), smooth=False)
    # Front Radiator Grille
    b.add_box(c_chrome, (0, 1.84, 0.58), (0.84, 0.08, 0.28), smooth=False)
    b.add_box(c_dark_chassis, (0, 1.86, 0.58), (0.76, 0.06, 0.22), smooth=False)
    # Horizontal grille slats
    for gy in (0.52, 0.58, 0.64):
        b.add_box(c_chrome, (0, 1.87, gy), (0.74, 0.05, 0.03), smooth=False)

    # Two Big Friendly Round Headlights (X = +/-0.56m, Y = 1.84m, Z = 0.62m)
    for hx in (-0.56, 0.56):
        b.add_cylinder(c_chrome, (hx, 1.82, 0.62), 0.15, 0.15, 0.10, segments=12, rot=(0.5 * math.pi, 0, 0))
        b.add_sphere(c_headlight, (hx, 1.86, 0.62), 0.13, scale=(1.0, 0.5, 1.0), subdivisions=1, smooth=True)
        # Cute amber turn indicator below headlight
        b.add_sphere(c_amber_light, (hx, 1.86, 0.46), 0.055, scale=(1.0, 0.5, 1.0), subdivisions=1, smooth=True)

    # 6. Rear End: Bumper, Taillights, License Plate
    # Rear Chrome Bumper at Y = -1.86m, Z = 0.38m
    b.add_box(c_chrome, (0, -1.86, 0.38), (1.58, 0.12, 0.14), smooth=False)
    # Taillight clusters
    for rx in (-0.60, 0.60):
        b.add_box(c_chrome, (rx, -1.84, 0.64), (0.24, 0.06, 0.18), smooth=False)
        b.add_box(c_taillight_red, (rx, -1.86, 0.67), (0.20, 0.05, 0.09), smooth=False) # Red brake
        b.add_box(c_amber_light, (rx, -1.86, 0.59), (0.20, 0.05, 0.06), smooth=False) # Amber turn

    # Dual Aerodynamic Side View Mirrors
    for sx in (-0.76, 0.76):
        sign_x = 1.0 if sx > 0 else -1.0
        # Mirror stalk
        b.add_cylinder(c_chrome, (sx, 0.72, 0.92), 0.02, 0.02, 0.14, rot=(0, sign_x * 0.4, 0))
        # Oval mirror housing
        b.add_sphere(c_taxi_yellow, (sx + sign_x * 0.10, 0.72, 0.95), 0.08, scale=(0.5, 1.2, 0.9), subdivisions=1, smooth=True)
        # Mirror glass
        b.add_box(c_chrome, (sx + sign_x * 0.08, 0.72, 0.95), (0.02, 0.15, 0.12), smooth=False)

    b.finalize_and_export(os.path.join(OUT_DIR, "prop_city_car.glb"))


# ==============================================================================
# 6. mega_lighthouse.glb: Coastal Seaside Lighthouse
#    Height ~21m, base ~6x6m. Traditional tapering red-and-white stone tower on a
#    dark sea-rock foundation, upper lantern room with observation railing and
#    glass beacon chamber, conical roof. Grounded at Y_min = 0.0000.
# ==============================================================================
def sculpt_lighthouse():
    b = PropBuilder("mega_lighthouse")

    # Palette
    c_rock = b.mat("sea_cliff_rock", "#383E44", roughness=0.88)
    c_red_band = b.mat("maritime_red", "#B82C24", roughness=0.78)
    c_white_band = b.mat("sea_salt_white", "#EAE5DC", roughness=0.80)
    c_stone_trim = b.mat("granite_trim", "#8A929A", roughness=0.82)
    c_iron_railing = b.mat("wrought_iron", "#282C32", roughness=0.60, metallic=0.75)
    c_brass_lens = b.mat("fresnel_brass", "#D4AF37", roughness=0.30, metallic=0.85)
    c_beacon_glow = b.mat("beacon_light", "#FFF4B0", roughness=0.20, emission_hex="#FFF4B0", emission_strength=4.0)
    c_copper_roof = b.mat("copper_patina", "#426D64", roughness=0.72)
    c_door = b.mat("oak_entrance", "#4C3020", roughness=0.78)
    c_window_glow = b.mat("window_lantern", "#FFDF96", roughness=0.20, emission_hex="#FFDF96", emission_strength=2.0)

    # 1. Rugged Dark Sea-Rock Foundation (Base 6.2m x 6.2m, Z from 0.0 to 2.8m)
    # Natural cliff-like stepped stone tiers
    b.add_cylinder(c_rock, (0, 0, 0.4), 3.2, 3.0, 0.8, segments=12, smooth=False)
    b.add_cylinder(c_rock, (0, 0, 1.2), 2.9, 2.7, 0.8, segments=12, smooth=False)
    b.add_cylinder(c_rock, (0, 0, 2.0), 2.6, 2.4, 0.8, segments=12, smooth=False)
    b.add_cylinder(c_rock, (0, 0, 2.6), 2.4, 2.3, 0.6, segments=12, smooth=False)

    # Stone Stairs cut into the rock base (from Z=0.0 to Z=2.8m in front at Y = -2.6m)
    for si, step_z in enumerate((0.35, 0.70, 1.05, 1.40, 1.75, 2.10, 2.45, 2.80)):
        step_y = -3.2 + si * 0.22
        b.add_box(c_stone_trim, (0, step_y, step_z * 0.5), (1.6 - si * 0.05, 0.35, step_z), smooth=False)

    # Heavy Arched Oak Entrance Doorway at Z=2.8m
    b.add_box(c_stone_trim, (0, -2.15, 3.8), (1.6, 0.4, 2.4), smooth=False)
    b.add_box(c_door, (0, -2.25, 3.7), (1.1, 0.2, 2.1), smooth=False)

    # 2. Conical Tapering Stone Tower (Diameter 4.2m at Z=2.8m tapering to 2.6m at Z=16.5m)
    # 4 Classic Alternating Maritime Bands:
    # Band 1: Maritime Red (Z from 2.7m to 6.2m)
    b.add_cylinder(c_red_band, (0, 0, 4.45), 2.10, 1.90, 3.5, segments=16, smooth=True)
    # Band 2: Sea-Salt White (Z from 6.1m to 9.6m)
    b.add_cylinder(c_white_band, (0, 0, 7.85), 1.90, 1.70, 3.5, segments=16, smooth=True)
    # Band 3: Maritime Red (Z from 9.5m to 13.0m)
    b.add_cylinder(c_red_band, (0, 0, 11.25), 1.70, 1.50, 3.5, segments=16, smooth=True)
    # Band 4: Sea-Salt White (Z from 12.9m to 16.5m)
    b.add_cylinder(c_white_band, (0, 0, 14.70), 1.50, 1.30, 3.6, segments=16, smooth=True)

    # Lookout Windows with Stone Sills along the Tower (at Z=5.0m, Z=8.5m, Z=12.0m)
    for wz, w_radius in ((5.0, 2.00), (8.5, 1.80), (12.0, 1.60)):
        b.add_box(c_stone_trim, (0, -w_radius - 0.05, wz), (0.8, 0.3, 1.2), smooth=False)
        b.add_box(c_window_glow, (0, -w_radius - 0.12, wz), (0.5, 0.1, 0.9), smooth=False)

    # 3. Flared Corbelled Observation Gallery (Z from 16.4m to 17.6m)
    # Flared stone corbels expanding from 1.3m to 1.8m radius
    gallery_profile = [
        (1.30, 16.4), (1.45, 16.8), (1.75, 17.2), (1.85, 17.5), (1.80, 17.6)
    ]
    b.add_lathe(c_stone_trim, (0, 0), gallery_profile, segments=16, smooth=True)

    # Wrought-Iron Safety Railing encircling the Observation Deck (radius 1.80m, height 1.1m)
    # Top handrail
    b.add_torus(c_iron_railing, (0, 0, 18.6), 1.78, 0.035, seg_major=20, seg_minor=6)
    b.add_torus(c_iron_railing, (0, 0, 18.1), 1.78, 0.025, seg_major=20, seg_minor=6) # Mid rail
    # 16 Vertical Stanchions
    for i in range(16):
        ang = 2.0 * math.pi * i / 16.0
        rx, ry = 1.78 * math.cos(ang), 1.78 * math.sin(ang)
        b.add_cylinder(c_iron_railing, (rx, ry, 18.1), 0.03, 0.03, 1.1, segments=6)

    # 4. Glass Lantern Room & Fresnel Beacon Chamber (Z from 17.5m to 19.8m, radius 1.25m)
    # Lantern Room Base Plinth
    b.add_cylinder(c_stone_trim, (0, 0, 17.8), 1.30, 1.30, 0.4, segments=16)

    # 8 Structural Bronze Struts around glass chamber
    for i in range(8):
        ang = 2.0 * math.pi * i / 8.0
        bx, by = 1.22 * math.cos(ang), 1.22 * math.sin(ang)
        b.add_cylinder(c_iron_railing, (bx, by, 18.8), 0.04, 0.04, 1.8, segments=6)

    # Glass Beacon Core Cylinder
    b.add_cylinder(c_white_band, (0, 0, 18.8), 1.18, 1.18, 1.8, segments=16, smooth=True)

    # Fresnel Brass Lens Assembly & Powerful Glowing Beacon Core
    b.add_cylinder(c_brass_lens, (0, 0, 18.4), 0.55, 0.55, 0.3, segments=12)
    b.add_cylinder(c_beacon_glow, (0, 0, 18.8), 0.48, 0.48, 0.7, segments=12, smooth=True)
    b.add_torus(c_brass_lens, (0, 0, 18.8), 0.52, 0.05, seg_major=12, seg_minor=6)
    b.add_cylinder(c_brass_lens, (0, 0, 19.2), 0.55, 0.55, 0.3, segments=12)

    # 5. Conical Copper Patina Roof & Weather Vane Finial (Z from 19.7m to 21.2m)
    # Copper Roof Eave
    b.add_cylinder(c_copper_roof, (0, 0, 19.8), 1.40, 1.40, 0.15, segments=16)
    # Conical Roof tapering to apex at Z=20.8m
    b.add_cylinder(c_copper_roof, (0, 0, 20.3), 1.38, 0.12, 1.0, segments=16, smooth=True)

    # Finial Ball & Weather Vane reaching 21.2m
    b.add_sphere(c_brass_lens, (0, 0, 20.85), 0.15, subdivisions=1, smooth=True)
    b.add_cylinder(c_iron_railing, (0, 0, 21.05), 0.03, 0.015, 0.4, segments=6)
    # 4 Cardinal arms (N, S, E, W)
    b.add_box(c_iron_railing, (0, 0, 21.05), (0.6, 0.03, 0.03), smooth=False)
    b.add_box(c_iron_railing, (0, 0, 21.05), (0.03, 0.6, 0.03), smooth=False)

    b.finalize_and_export(os.path.join(OUT_DIR, "mega_lighthouse.glb"))


def main():
    print("==================================================================")
    print("SCULPTING CHAPTER 1 ASSETS: Track L1-B (6 AAA Models)")
    print("==================================================================")
    sculpt_skyscraper_a()
    sculpt_skyscraper_b()
    sculpt_family_house()
    sculpt_birthday_table()
    sculpt_city_car()
    sculpt_lighthouse()
    print("ALL 6 ASSETS SCULPTED & EXPORTED SUCCESSFULLY!")


if __name__ == "__main__":
    main()
