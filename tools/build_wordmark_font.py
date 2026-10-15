#!/usr/bin/env python3
"""Add Lightning's logo glyph to a static Roboto TTF using only Python's stdlib.

Usage: python3 tools/build_wordmark_font.py path/to/Roboto-Medium.ttf
The original glyphs and their hinting are retained. The new U+E000 glyph gets
simple baseline/cap-height and horizontal grid fitting for small display sizes.
"""
from pathlib import Path
import argparse
import struct


def u16(data, offset):
    return struct.unpack_from('>H', data, offset)[0]


def u32(data, offset):
    return struct.unpack_from('>I', data, offset)[0]


def pad(data):
    return data + b'\0' * (-len(data) % 4)


def checksum(data):
    padded = pad(data)
    return sum(struct.unpack(f'>{len(padded) // 4}I', padded)) & 0xFFFFFFFF


def unicode_map(table):
    result = {}
    for index in range(u16(table, 2)):
        platform, encoding, offset = struct.unpack_from('>HHI', table, 4 + index * 8)
        if platform not in (0, 3):
            continue
        sub = table[offset:]
        kind = u16(sub, 0)
        if kind == 4:
            count = u16(sub, 6) // 2
            for segment in range(count):
                end = u16(sub, 14 + segment * 2)
                start = u16(sub, 16 + count * 2 + segment * 2)
                delta = u16(sub, 16 + count * 4 + segment * 2)
                pointer = 16 + count * 6 + segment * 2
                distance = u16(sub, pointer)
                for codepoint in range(start, min(end, 0xFFFE) + 1):
                    glyph = u16(sub, pointer + distance + (codepoint - start) * 2) if distance else codepoint
                    if glyph or not distance:
                        result[codepoint] = (glyph + delta) & 0xFFFF
        elif kind == 12:
            for group in range(u32(sub, 12)):
                start, end, first = struct.unpack_from('>III', sub, 16 + group * 12)
                for codepoint in range(start, end + 1):
                    result[codepoint] = first + codepoint - start
    return result


def make_cmap(mapping):
    groups = []
    for cp, glyph in sorted(mapping.items()):
        if groups and cp == groups[-1][1] + 1 and glyph == groups[-1][2] + cp - groups[-1][0]:
            groups[-1][1] = cp
        else:
            groups.append([cp, cp, glyph])
    sub = struct.pack('>HHIII', 12, 0, 16 + 12 * len(groups), 0, len(groups))
    sub += b''.join(struct.pack('>III', *group) for group in groups)
    return struct.pack('>HHHHIHHI', 0, 2, 0, 4, 20, 3, 10, 20) + sub


def make_names(original):
    names = {
        1: 'Lightning Wordmark', 2: 'Regular',
        3: 'LightningWordmark-Regular-1.0', 4: 'Lightning Wordmark',
        5: 'Version 1.000', 6: 'LightningWordmark-Regular',
        16: 'Lightning Wordmark', 17: 'Regular',
        10: 'Modified from Roboto Medium: adds a grid-fitted lightning glyph at U+E000.',
    }
    storage = u16(original, 4)
    for index in range(u16(original, 2)):
        platform, encoding, language, name_id, length, offset = struct.unpack_from('>6H', original, 6 + index * 12)
        if platform == 3 and name_id in (0, 13, 14):
            names[name_id] = original[storage + offset:storage + offset + length].decode('utf-16-be')
    records, strings = [], b''
    for name_id, text in sorted(names.items()):
        encoded = text.encode('utf-16-be')
        records.append(struct.pack('>6H', 3, 1, 0x0409, name_id, len(encoded), len(strings)))
        strings += encoded
    return struct.pack('>3H', 0, len(records), 6 + 12 * len(records)) + b''.join(records) + strings


def build(source, output):
    data = source.read_bytes()
    if data[:4] != b'\0\1\0\0':
        raise ValueError('Expected a static TrueType font with glyf outlines.')
    tables = {}
    for index in range(u16(data, 4)):
        tag, _, offset, length = struct.unpack_from('>4sIII', data, 12 + index * 16)
        tables[tag] = data[offset:offset + length]
    if u16(tables[b'head'], 18) != 2048:
        raise ValueError('This glyph is designed for a 2048-unit Roboto source font.')
    count = u16(tables[b'maxp'], 4)
    mapping = unicode_map(tables[b'cmap'])
    if 0xE000 in mapping:
        raise ValueError('The source font already uses U+E000.')

    # Clockwise outline in font coordinates: clipped tips, substantial middle.
    points = [(400, 1456), (650, 1456), (430, 850), (800, 850),
              (260, 0), (100, 0), (310, 650), (40, 650)]
    # SVTCA[y], RTG, round cap/baseline points with MDAP, interpolate y;
    # then round left/right edges and interpolate x. No CVT/function dependency.
    instructions = bytes([0x00, 0x18, 0xB3, 0, 1, 4, 5,
                          0x2F, 0x2F, 0x2F, 0x2F, 0x30,
                          0x01, 0xB1, 7, 3, 0x2F, 0x2F, 0x31])
    glyph = struct.pack('>5hHH', 1, 40, 0, 800, 1456, 7, len(instructions))
    glyph += instructions + bytes([1] * len(points))
    for axis in (0, 1):
        previous = 0
        for point in points:
            glyph += struct.pack('>h', point[axis] - previous)
            previous = point[axis]

    head = bytearray(tables[b'head'])
    long_offsets = struct.unpack_from('>h', head, 50)[0] == 1
    offsets = [u32(tables[b'loca'], i * 4) if long_offsets else u16(tables[b'loca'], i * 2) * 2
               for i in range(count + 1)]
    glyf = tables[b'glyf'][:offsets[-1]] + pad(glyph)
    tables[b'glyf'] = glyf
    tables[b'loca'] = b''.join(struct.pack('>I', offset) for offset in offsets + [len(glyf)])
    struct.pack_into('>h', head, 50, 1)
    struct.pack_into('>I', head, 8, 0)
    tables[b'head'] = bytes(head)

    hhea = bytearray(tables[b'hhea'])
    metric_count = u16(hhea, 34)
    hmtx = tables[b'hmtx'][:metric_count * 4]
    last_advance = u16(hmtx, (metric_count - 1) * 4)
    for i in range(count - metric_count):
        lsb = struct.unpack_from('>h', tables[b'hmtx'], metric_count * 4 + i * 2)[0]
        hmtx += struct.pack('>Hh', last_advance, lsb)
    tables[b'hmtx'] = hmtx + struct.pack('>Hh', 850, 40)
    struct.pack_into('>H', hhea, 34, count + 1)
    tables[b'hhea'] = bytes(hhea)
    maxp = bytearray(tables[b'maxp'])
    struct.pack_into('>H', maxp, 4, count + 1)
    for offset, minimum in [(6, len(points)), (8, 1), (24, 4), (26, len(instructions))]:
        struct.pack_into('>H', maxp, offset, max(u16(maxp, offset), minimum))
    tables[b'maxp'] = bytes(maxp)
    mapping[0xE000] = count
    tables[b'cmap'] = make_cmap(mapping)
    tables[b'name'] = make_names(tables[b'name'])
    tables[b'post'] = struct.pack('>I', 0x00030000) + tables[b'post'][4:32]
    tables.pop(b'DSIG', None)

    total = len(tables)
    power = 1 << (total.bit_length() - 1)
    header = struct.pack('>IHHHH', 0x00010000, total, power * 16, power.bit_length() - 1, (total - power) * 16)
    directory, payload = b'', b''
    for tag, table in sorted(tables.items()):
        offset = 12 + 16 * total + len(payload)
        directory += struct.pack('>4sIII', tag, checksum(table), offset, len(table))
        payload += pad(table)
    result = bytearray(header + directory + payload)
    head_index = sorted(tables).index(b'head')
    head_offset = u32(result, 12 + head_index * 16 + 8)
    struct.pack_into('>I', result, head_offset + 8, (0xB1B0AFBA - checksum(result)) & 0xFFFFFFFF)
    assert checksum(result) == 0xB1B0AFBA
    assert unicode_map(tables[b'cmap'])[0xE000] == count
    assert u16(tables[b'maxp'], 4) == count + 1
    assert len(tables[b'hmtx']) == (count + 1) * 4
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(result)
    print(f'Built {output}: {len(result)} bytes; lightning glyph U+E000; checksum verified.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--output', type=Path, default=Path('assets/fonts/LightningWordmark.ttf'))
    args = parser.parse_args()
    build(args.source, args.output)
