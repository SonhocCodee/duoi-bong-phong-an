#!/usr/bin/env python3
"""Hau xu ly sau build_city: chen override sprite_frames cho NPC thanh
(instance con khong luu duoc qua pack). Chay lai sau moi lan build lai thanh.
Usage: python3 city_sprite_overrides.py <path thanh_xuan_lam.tscn>"""
import re
import sys

p = sys.argv[1]
src = open(p).read()
if 'tho_ren_frames.tres' in src:
    print('da co override, bo qua')
    sys.exit(0)
lines = src.split('\n')
m = re.match(r'\[gd_scene load_steps=(\d+)', lines[0])
steps = int(m.group(1))
new_ext = [
    '[ext_resource type="SpriteFrames" path="res://assets/sprites/tho_ren_frames.tres" id="12_thorf"]',
    '[ext_resource type="SpriteFrames" path="res://assets/sprites/linh_tuan_frames.tres" id="13_linhtf"]',
    '[ext_resource type="SpriteFrames" path="res://assets/sprites/nong_dan_frames.tres" id="14_nongdf"]',
]
last_ext = max(i for i, l in enumerate(lines) if l.startswith('[ext_resource'))
for j, e in enumerate(new_ext):
    lines.insert(last_ext + 1 + j, e)
lines[0] = lines[0].replace('load_steps=%d' % steps, 'load_steps=%d' % (steps + 3), 1)

npc_id = None
for l in lines:
    mm = re.search(r'path="res://systems/npc\.tscn" id="([^"]+)"', l)
    if mm:
        npc_id = mm.group(1)
assert npc_id, 'khong tim thay ext_resource npc.tscn'

overrides = {
    'NPC_ThoRen': '12_thorf',
    'NPC_LinhGac': '13_linhtf',
    'NPC_LinhGacNam': '13_linhtf',
    'NPC_LinhTuanA': '13_linhtf',
    'NPC_LinhTuanB': '13_linhtf',
    'NPC_LinhCanhNoi': '13_linhtf',
    'NPC_GanhNuoc': '14_nongdf',
}
out = []
i = 0
done = set()
while i < len(lines):
    out.append(lines[i])
    mm = re.match(r'\[node name="(NPC_\w+)" type="CharacterBody2D" parent="\." instance=', lines[i])
    if mm and mm.group(1) in overrides and mm.group(1) not in done:
        name = mm.group(1)
        i += 1
        while i < len(lines) and not lines[i].startswith('[node'):
            out.append(lines[i])
            i += 1
        out.append('[node name="AnimatedSprite2D" parent="%s"]' % name)
        out.append('sprite_frames = ExtResource("%s")' % overrides[name])
        out.append('')
        done.add(name)
        continue
    i += 1
open(p, 'w').write('\n'.join(out))
print('overrides applied:', sorted(done))
