#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh lại toàn bộ file nhị phân (PNG...) từ bản mã hoá base64 (.b64) trong repo.

Vì sao cần script này: kênh push GitHub của Muse chỉ đẩy được file văn bản,
nên mọi asset nhị phân được lưu trong repo dưới dạng <tên-file>.b64 (UTF-8).
Chạy script này 1 lần sau khi clone (và sau mỗi lần pull có asset mới):

    python tools/restore_assets.py

Chỉ dùng thư viện chuẩn của Python — không cần cài thêm gì.
"""
import base64
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main() -> int:
    restored = 0
    for dirpath, _dirnames, filenames in os.walk(ROOT):
        if ".git" in dirpath.split(os.sep):
            continue
        for name in filenames:
            if not name.endswith(".b64"):
                continue
            src = os.path.join(dirpath, name)
            dst = src[: -len(".b64")]
            with open(src, "r", encoding="ascii") as f:
                data = base64.b64decode(f.read())
            with open(dst, "wb") as f:
                f.write(data)
            restored += 1
            print("restored:", os.path.relpath(dst, ROOT), f"({len(data)} bytes)")
    print(f"Done. {restored} asset(s) restored.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
