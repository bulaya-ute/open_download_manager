# python
import sys
import os

CHUNK = 8192

def hex_bytes(b):
    return ' '.join(f'{x:02x}' for x in b)

def context_hex(path, offset, context):
    with open(path, 'rb') as f:
        start = max(0, offset - context)
        f.seek(start)
        data = f.read(context * 2 + 1)
    return start, data

def compare_files(path_a, path_b, max_diffs=20, context=16):
    size_a = os.path.getsize(path_a)
    size_b = os.path.getsize(path_b)
    print(f"{path_a}: {size_a} bytes")
    print(f"{path_b}: {size_b} bytes")

    diffs = []
    total_diffs = 0
    offset = 0

    with open(path_a, 'rb') as fa, open(path_b, 'rb') as fb:
        while True:
            a = fa.read(CHUNK)
            b = fb.read(CHUNK)
            if not a and not b:
                break

            minlen = min(len(a), len(b))
            if a[:minlen] != b[:minlen]:
                # find differing bytes within this chunk
                for i in range(minlen):
                    if a[i] != b[i]:
                        total_diffs += 1
                        if len(diffs) < max_diffs:
                            diffs.append(offset + i)
                # continue scanning remaining bytes in this chunk range
                # (we already counted differences above)
            # if chunk lengths differ, account for trailing bytes as differences
            if len(a) != len(b):
                extra = abs(len(a) - len(b))
                total_diffs += extra
                if len(diffs) < max_diffs:
                    # record offsets for some of the extra bytes (up to remaining slots)
                    start_extra = offset + minlen
                    slots_left = max_diffs - len(diffs)
                    for j in range(min(slots_left, extra)):
                        diffs.append(start_extra + j)

            offset += max(len(a), len(b))

    print(f"Total differing bytes (approx): {total_diffs}")
    if not diffs:
        if size_a != size_b:
            print("Files differ only by length (no byte mismatches in overlapping region).")
        else:
            print("Files appear identical in the compared regions.")
        return

    print(f"Showing up to {len(diffs)} differences (context = {context} bytes):")
    for d in diffs:
        a_start, a_chunk = context_hex(path_a, d, context)
        b_start, b_chunk = context_hex(path_b, d, context)
        idx_in_chunk = d - a_start
        # hex lines
        a_hex = hex_bytes(a_chunk)
        b_hex = hex_bytes(b_chunk)
        # pointer line with caret under differing byte
        # compute caret position in characters: each byte = 2 hex + 1 space => 3 chars, minus final space
        caret_pos = idx_in_chunk * 3
        pointer_line = ' ' * caret_pos + '^'

        print(f"\nOffset: {d} (0x{d:x})")
        print(f"{path_a} @ {a_start}:")
        print(a_hex)
        print(pointer_line)
        print(f"{path_b} @ {b_start}:")
        print(b_hex)
        print(pointer_line)

if __name__ == '__main__':
    file1 = "/home/bulaya/Downloads/Videos/Big_Buck_Bunny_360_10s_5MB.mp4"
    file2 = "/home/bulaya/Downloads/ODM Downloads/Big_Buck_Bunny_360_10s_5MB.mp4"
    # maxd = int(sys.argv[3]) if len(sys.argv) > 3 else 20
    # ctx = int(sys.argv[4]) if len(sys.argv) > 4 else 16
    compare_files(file1, file2, )
