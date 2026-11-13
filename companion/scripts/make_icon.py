"""Generate the companion's opaque geometric app icon using only the standard library."""
from pathlib import Path
import math
import struct
import zlib

size = 1024
rows = bytearray()
for y in range(size):
    rows.append(0)
    for x in range(size):
        t = (x + y) / (2 * size)
        color = [round(16 + 12 * t), round(91 + 40 * t), round(91 + 35 * t)]
        # Two open circles, representing a connection without merging identities.
        left = math.hypot(x - 395, y - 512)
        right = math.hypot(x - 629, y - 512)
        if 163 < left < 208 or 163 < right < 208:
            color = [242, 250, 247]
        rows.extend(color)

def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(rows), 9))
png += chunk(b"IEND", b"")
target = Path(__file__).resolve().parents[1] / "AllOfMeCompanion/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(png)
