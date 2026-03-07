"""Embed a Godot PCK file into an APK using Godot's embedded PCK format.

Godot looks for PCK data embedded at the end of the executable/APK.
The format is:
  [APK data] [PCK data] [embed marker]

The embed marker at the very end is:
  - 64 bytes of zeros (padding)
  - 4 bytes: magic "GDPC" (0x47445043)
  - 8 bytes: PCK data size (uint64 LE, size of PCK file)
  - 4 bytes: main magic 0x43504447 ("GDPC" reversed = "CPGD" but actually 0x43504447)

Actually, Godot's self-contained PCK embed format appends:
  [PCK file contents]
  [8 bytes: offset where PCK starts in the file, uint64 LE]
  [4 bytes: magic 0x43504447]
"""
import struct
import sys
import os

def embed_pck(apk_path, pck_path, output_path):
    with open(apk_path, 'rb') as f:
        apk_data = f.read()

    with open(pck_path, 'rb') as f:
        pck_data = f.read()

    pck_offset = len(apk_data)

    with open(output_path, 'wb') as f:
        # Write APK data
        f.write(apk_data)
        # Write PCK data
        f.write(pck_data)
        # Write PCK offset (where in the file the PCK starts)
        f.write(struct.pack('<Q', pck_offset))
        # Write magic marker that Godot looks for
        f.write(struct.pack('<I', 0x43504447))

    total_size = os.path.getsize(output_path)
    print(f"APK size: {len(apk_data)} bytes ({len(apk_data)/1024/1024:.1f} MB)")
    print(f"PCK size: {len(pck_data)} bytes ({len(pck_data)/1024:.1f} KB)")
    print(f"Total size: {total_size} bytes ({total_size/1024/1024:.1f} MB)")
    print(f"PCK offset: {pck_offset}")
    print("Embed complete!")

if __name__ == '__main__':
    embed_pck(sys.argv[1], sys.argv[2], sys.argv[3])
