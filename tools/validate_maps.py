#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kiểm chứng sơ đồ liên kết map: mọi portal trong maps/*.tscn phải trỏ tới scene tồn tại
và scene đích phải có Marker2D tên Spawn_<target_spawn>. Chạy: python3 tools/validate_maps.py
Thoát mã 1 nếu có liên kết hỏng."""
import os, re, sys

MAPS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "game", "maps")

def parse(path):
    txt = open(path, encoding="utf-8").read()
    markers = set(re.findall(r'\[node name="(Spawn_[^"]+)" type="Marker2D"', txt))
    portal_ids = set(re.findall(r'\[ext_resource type="PackedScene" path="res://systems/portal.tscn" id="([^"]+)"\]', txt))
    portals = []
    for m in re.finditer(r'\[node name="([^"]+)" parent="\." instance=ExtResource\("([^"]+)"\)\](.*?)(?=\n\[node |\Z)', txt, re.S):
        if m.group(2) not in portal_ids:
            continue
        body = m.group(3)
        ts = re.search(r'target_scene = "res://maps/([^"]+)"', body)
        tsp = re.search(r'target_spawn = "([^"]+)"', body)
        if ts and tsp:
            portals.append((m.group(1), ts.group(1), tsp.group(1)))
    return markers, portals

def main():
    scenes = {}
    for f in sorted(os.listdir(MAPS)):
        if f.endswith(".tscn"):
            scenes[f] = parse(os.path.join(MAPS, f))
    errors = 0
    total_portals = 0
    for f, (markers, portals) in scenes.items():
        for name, target, spawn in portals:
            total_portals += 1
            if target not in scenes:
                print(f"LOI: {f} portal {name} -> scene khong ton tai: {target}")
                errors += 1
            elif f"Spawn_{spawn}" not in scenes[target][0]:
                print(f"LOI: {f} portal {name} -> {target} thieu marker Spawn_{spawn}")
                errors += 1
    print(f"Tong: {len(scenes)} scene, {total_portals} portal, {errors} loi lien ket")
    for f, (markers, portals) in scenes.items():
        print(f" - {f}: {len(portals)} portal, markers: {sorted(markers)}")
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())
