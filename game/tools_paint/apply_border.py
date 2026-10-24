#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TEAM VIEN MAP - buoc 2: AP ke hoach vien map vao .tscn bang TEXT.

Doc /tmp/border_plan.json (do game/tools_paint/border_plan.gd xuat) va
CHEN node "MapBorder" (Node2D y-sort) + cac prop vien dang Sprite2D vao
cuoi file map, giu nguyen 100% noi dung goc (khong pack+save bang Godot
- packer lam roi override tren node con cua instance).

Idempotent: chay lai se xoa block MapBorder + ext "bor_*" cua lan truoc
roi chen lai; load_steps duoc dieu chinh theo chenh lech ext thuc te.

Chay: python3 game/tools_paint/apply_border.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLAN_PATH = "/tmp/border_plan.json"


def fmt_num(v):
    v = float(v)
    if abs(v - round(v)) < 1e-9:
        return str(int(round(v)))
    return ("%.4f" % v).rstrip("0").rstrip(".")


def split_nodes(txt):
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


def is_border_block(header):
    m = re.search(r'\[node name="([^"]+)"', header)
    name = m.group(1) if m else ""
    parent = re.search(r'parent="([^"]*)"', header)
    parent = parent.group(1) if parent else ""
    return name == "MapBorder" or parent == "MapBorder" or parent.startswith("MapBorder/")


def apply_map(res_path, plan):
    rel = res_path.replace("res://", "")
    fpath = os.path.join(ROOT, "game", rel)
    txt = open(fpath, encoding="utf-8").read()

    # --- Don dot truoc (idempotent) ---
    removed_ext = len(re.findall(r'^\[ext_resource [^\]]*id="bor_[^"]*"[^\]]*\]\n', txt, flags=re.M))
    txt = re.sub(r'^\[ext_resource [^\]]*id="bor_[^"]*"[^\]]*\]\n', "", txt, flags=re.M)
    prefix, blocks = split_nodes(txt)
    blocks = [(h, b) for (h, b) in blocks if not is_border_block(h)]
    txt = prefix + "".join(b for _, b in blocks)

    # --- ext_resource hien co: path -> id ---
    ext = {}
    for m in re.finditer(r'\[ext_resource type="([^"]+)" path="([^"]+)" id="([^"]+)"\]', txt):
        ext[m.group(2)] = m.group(3)

    need_tex = []
    for it in plan["props"]:
        p = "res://assets/props/%s.png" % it["tex"]
        if p not in ext and p not in need_tex:
            need_tex.append(p)
    new_ext_lines = []
    for p in need_tex:
        rid = "bor_" + os.path.basename(p).replace(".png", "")
        ext[p] = rid
        new_ext_lines.append('[ext_resource type="Texture2D" path="%s" id="%s"]' % (p, rid))

    if new_ext_lines or removed_ext:
        if new_ext_lines:
            matches = list(re.finditer(r'^\[ext_resource [^\]]*\]\n', txt, flags=re.M))
            pos = matches[-1].end()
            txt = txt[:pos] + "\n".join(new_ext_lines) + "\n" + txt[pos:]
        delta = len(new_ext_lines) - removed_ext
        if delta != 0:
            def bump(m):
                return "load_steps=%d" % (int(m.group(1)) + delta)
            txt = re.sub(r"load_steps=(\d+)", bump, txt, count=1)

    out = []
    out.append('[node name="MapBorder" type="Node2D" parent="."]\n'
               "y_sort_enabled = true\n")
    for it in plan["props"]:
        name = "B_%s_%03d" % (it["tex"], int(it["seq"]))
        tex_id = ext["res://assets/props/%s.png" % it["tex"]]
        scl = float(it["scl"])
        off_y = -float(it["h"]) * scl / 2.0 + 8.0
        flip = "\nflip_h = true" if it["flip"] else ""
        out.append(
            '[node name="%s" type="Node2D" parent="MapBorder"]\n'
            "position = Vector2(%s, %s)\n"
            "y_sort_enabled = true\n"
            "\n"
            '[node name="Sprite2D" type="Sprite2D" parent="MapBorder/%s"]\n'
            "position = Vector2(0, %s)\n"
            "scale = Vector2(%s, %s)\n"
            'texture = ExtResource("%s")%s\n'
            % (name, fmt_num(it["x"]), fmt_num(it["y"]), name,
               fmt_num(off_y), fmt_num(scl), fmt_num(scl), tex_id, flip))

    # Chuan hoa cuoi file truoc khi noi: chay lai nhieu lan van ra dung
    # mot noi dung (idempotent tuyet doi).
    txt = txt.rstrip() + "\n"
    txt += "\n" + "\n".join(out)
    open(fpath, "w", encoding="utf-8").write(txt)
    print("%s: +border props=%d (ext moi: %d)"
          % (os.path.basename(fpath), len(plan["props"]), len(new_ext_lines)))


def main():
    plan = json.load(open(PLAN_PATH, encoding="utf-8"))
    for res_path, p in plan.items():
        apply_map(res_path, p)
    print("APPLY BORDER: xong %d map" % len(plan))


if __name__ == "__main__":
    main()
