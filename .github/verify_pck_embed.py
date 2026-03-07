"""Verify that a PCK is properly embedded at the end of an APK."""
import struct
import sys

apk_path = sys.argv[1]

with open(apk_path, 'rb') as f:
    # Read magic at end of file
    f.seek(-4, 2)
    magic = struct.unpack('<I', f.read(4))[0]

    # Read PCK offset
    f.seek(-12, 2)
    offset = struct.unpack('<Q', f.read(8))[0]

    if magic == 0x43504447:
        print('PCK embed marker: FOUND (magic=0x{:08X})'.format(magic))
        print('PCK offset in APK: {}'.format(offset))

        # Verify PCK header at that offset
        f.seek(offset, 0)
        pck_magic = f.read(4)
        print('PCK header at offset: {}'.format(pck_magic))
        if pck_magic == b'GDPC':
            print('PCK header valid!')
        else:
            print('WARNING: PCK header mismatch')
            sys.exit(1)
    else:
        print('WARNING: No PCK embed marker (got 0x{:08X})'.format(magic))
        sys.exit(1)
