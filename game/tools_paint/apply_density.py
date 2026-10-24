#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TEAM 2-A Density pass - buoc 2: AP ke hoach vao file .tscn bang TEXT.

Doc /tmp/density_plan.json (do game/tools_paint/prop_density.gd xuat) va
CHEN cac block node moi vao cuoi tung file map, giu nguyen 100% noi dung
goc (pack+save bang Godot se lam roi override tren node con cua instance
nen tuyet doi khong dung cach do).

Chen:
- NPC phu: block [node ... instance=ExtResource(npc.tscn)] giong het dinh
  dang NPC san co trong file (tai dung ext_resource npc.tscn/npc.gd co san).
- "DensityProps" (Node2D, y_sort) + cac holder prop/decal con.
- ext_resource Texture2D moi cho texture chua co trong file (id "den_*"),
  load_steps += so ext_resource them.

Idempotent: chay lai se xoa block DensityProps / NPC_Density_* / ext
"den_*" cua lan truoc roi chen lai.

Chay: python3 game/tools_paint/apply_density.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLAN_PATH = "/tmp/density_plan.json"


def fmt_num(v):
    """So kieu Godot: nguyen -> '560', le -> gon toi 4 chu so thap phan."""
    v = float(v)
    if abs(v - round(v)) < 1e-9:
        return str(int(round(v)))
    return ("%.4f" % v).rstrip("0").rstrip(".")


def fmt_float(v):
    """Float trong Dictionary/Array: luon co phan thap phan ('560.0')."""
    v = float(v)
    if abs(v - round(v)) < 1e-9:
        return "%d.0" % int(round(v))
    return repr(round(v, 4))


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def split_nodes(txt):
    """Tra ve (prefix truoc [node dau tien, [(header_line, full_block), ...])."""
    idx = txt.find("[node ")
    if idx < 0:
        return txt, []
    prefix = txt[:idx]
    body = txt[idx:]
    parts = re.split(r"(?=\[node )", body)
    blocks = []
    for p in parts:
        if not p.strip():
            continue
        header = p.split("\n", 1)[0]
        blocks.append((header, p))
    return prefix, blocks


def is_density_block(header):
    m = re.search(r'\[node name="([^"]+)"', header)
    name = m.group(1) if m else ""
    parent = re.search(r'parent="([^"]*)"', header)
    parent = parent.group(1) if parent else ""
    if name == "DensityProps" or parent == "DensityProps" or parent.startswith("DensityProps/"):
        return True
    if name.startswith("NPC_Density_"):
        return True
    return False


def apply_map(res_path, plan):
    rel = res_path.replace("res://", "")
    fpath = os.path.join(ROOT, "game", rel)
    txt = open(fpath, encoding="utf-8").read()

    # --- Don dot truoc (idempotent) ---
    txt = re.sub(r'^\[ext_resource [^\]]*id="den_[^"]*"[^\]]*\]\n', "", txt, flags=re.M)
    prefix, blocks = split_nodes(txt)
    blocks = [(h, b) for (h, b) in blocks if not is_density_block(h)]
    txt = prefix + "".join(b for _, b in blocks)

    # --- ext_resource hien co: path -> id ---
    ext = {}
    for m in re.finditer(r'\[ext_resource type="([^"]+)" path="([^"]+)" id="([^"]+)"\]', txt):
        ext[m.group(2)] = m.group(3)

    need_tex = []
    for it in plan["props"] + plan["decals"]:
        p = "res://assets/props/%s.png" % it["tex"]
        if p not in ext and p not in need_tex:
            need_tex.append(p)
    new_ext_lines = []
    for p in need_tex:
        rid = "den_" + os.path.basename(p).replace(".png", "")
        ext[p] = rid
        new_ext_lines.append('[ext_resource type="Texture2D" path="%s" id="%s"]' % (p, rid))

    if new_ext_lines:
        # Chen sau dong ext_resource cuoi cung
        matches = list(re.finditer(r'^\[ext_resource [^\]]*\]\n', txt, flags=re.M))
        pos = matches[-1].end()
        txt = txt[:pos] + "\n".join(new_ext_lines) + "\n" + txt[pos:]
        # load_steps += so ext moi
        def bump(m):
            return "load_steps=%d" % (int(m.group(1)) + len(new_ext_lines))
        txt = re.sub(r"load_steps=(\d+)", bump, txt, count=1)

    out = []
    # --- NPC phu ---
    for npc in plan["npcs"]:
        npc_ps = ext.get("res://systems/npc.tscn")
        npc_gd = ext.get("res://systems/npc.gd")
        if npc_ps is None or npc_gd is None:
            print("LOI: %s thieu ext_resource npc.tscn/npc.gd" % res_path)
            sys.exit(1)
        steps = ", ".join(
            '{"x": %s, "y": %s, "action": "%s", "time": %s}'
            % (fmt_float(s[0]), fmt_float(s[1]), s[2], fmt_float(s[3]))
            for s in npc["steps"])
        done = ", ".join('"%s"' % esc(s) for s in npc["done"])
        tint = npc["tint"]
        out.append(
            '[node name="%s" type="CharacterBody2D" parent="." instance=ExtResource("%s")]\n'
            "y_sort_enabled = true\n"
            "position = Vector2(%s, %s)\n"
            'script = ExtResource("%s")\n'
            'npc_id = "%s"\n'
            'display_name = "%s"\n'
            "quest_ids = Array[String]([])\n"
            "dialogue_before = Array[String]([])\n"
            "dialogue_active = Array[String]([])\n"
            "dialogue_ready = Array[String]([])\n"
            "dialogue_done = Array[String]([%s])\n"
            "shop_enabled = false\n"
            "tint = Color(%s, %s, %s, %s)\n"
            "sprite_scale = 0.75\n"
            "wander_radius = 24.0\n"
            "wander_speed = 30.0\n"
            "schedule = Array[Dictionary]([%s])\n"
            "schedule_enabled = true\n"
            'work_anim = "work"\n'
            "speed = 55.0\n"
            % (npc["node"], npc_ps, fmt_num(npc["spawn"][0]), fmt_num(npc["spawn"][1]),
               npc_gd, npc["id"], esc(npc["display"]), done,
               fmt_num(tint[0]), fmt_num(tint[1]), fmt_num(tint[2]), fmt_num(tint[3]),
               steps))

    # --- DensityProps ---
    out.append('[node name="DensityProps" type="Node2D" parent="."]\n'
               "y_sort_enabled = true\n")
    for it in plan["props"]:
        name = "D_%s_%03d" % (it["tex"], int(it["seq"]))
        tex_id = ext["res://assets/props/%s.png" % it["tex"]]
        scl = float(it["scl"])
        off_y = -float(it["h"]) * scl / 2.0 + 8.0
        flip = "\nflip_h = true" if it["flip"] else ""
        out.append(
            '[node name="%s" type="Node2D" parent="DensityProps"]\n'
            "position = Vector2(%s, %s)\n"
            "y_sort_enabled = true\n"
            "\n"
            '[node name="Sprite2D" type="Sprite2D" parent="DensityProps/%s"]\n'
            "position = Vector2(0, %s)\n"
            "scale = Vector2(%s, %s)\n"
            'texture = ExtResource("%s")%s\n'
            % (name, fmt_num(it["x"]), fmt_num(it["y"]), name,
               fmt_num(off_y), fmt_num(scl), fmt_num(scl), tex_id, flip))
    for i, it in enumerate(plan["decals"]):
        name = "DDecal_%s_%03d" % (it["tex"], i)
        tex_id = ext["res://assets/props/%s.png" % it["tex"]]
        flip = "\nflip_h = true" if it["flip"] else ""
        out.append(
            '[node name="%s" type="Node2D" parent="DensityProps"]\n'
            "z_index = -5\n"
            "position = Vector2(%s, %s)\n"
            "rotation = %s\n"
            "\n"
            '[node name="Sprite2D" type="Sprite2D" parent="DensityProps/%s"]\n'
            "scale = Vector2(%s, %s)\n"
            'texture = ExtResource("%s")%s\n'
            % (name, fmt_num(it["x"]), fmt_num(it["y"]), fmt_num(it["rot"]),
               name, fmt_num(it["scl"]), fmt_num(it["scl"]), tex_id, flip))

    if not txt.endswith("\n"):
        txt += "\n"
    txt += "\n" + "\n".join(out)
    open(fpath, "w", encoding="utf-8").write(txt)
    print("%s: +props=%d +decals=%d +npcs=%d (ext moi: %d)"
          % (os.path.basename(fpath), len(plan["props"]), len(plan["decals"]),
             len(plan["npcs"]), len(new_ext_lines)))


def main():
    plan = json.load(open(PLAN_PATH, encoding="utf-8"))
    for res_path, p in plan.items():
        apply_map(res_path, p)
    print("APPLY DENSITY: xong %d map" % len(plan))


if __name__ == "__main__":
    main()
