"""Direct all-pairs clipping reference for bounded K-quadtree incidences."""

from __future__ import annotations

import struct
from fractions import Fraction

BAD = -1
NO_OUTPUT = -2
MAX_WORDS = 127
OUTPUT_BYTES = 376
WORKSPACE_BYTES = 16384


def _key4(point):
    x, y = point
    result = 0
    for shift in (7, 6, 5, 4):
        result = 4 * result + 2 * ((x >> shift) & 1) + ((y >> shift) & 1)
    return result


def _box(depth, prefix):
    x = y = 0
    for shift in range(2 * (depth - 1), -1, -2):
        digit = (prefix >> shift) & 3
        x = 2 * x + (digit >> 1)
        y = 2 * y + (digit & 1)
    side = 256 // (1 << depth)
    return x * side, y * side, (x + 1) * side, (y + 1) * side


def _fraction_clip(segment, rectangle):
    x0, y0, x1, y1 = rectangle
    ax, ay, bx, by = segment
    enter = Fraction(0, 1)
    leave = Fraction(1, 1)
    for origin, delta, low, high in ((ax, bx - ax, x0, x1),
                                    (ay, by - ay, y0, y1)):
        if delta == 0:
            if origin < low or origin > high:
                return False
            continue
        first = Fraction(low - origin, delta)
        last = Fraction(high - origin, delta)
        if first > last:
            first, last = last, first
        if first > enter:
            enter = first
        if last < leave:
            leave = last
        if enter > leave:
            return False
    return True


def _cross(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _between(a, b, p):
    return min(a[0], b[0]) <= p[0] <= max(a[0], b[0]) and min(a[1], b[1]) <= p[1] <= max(a[1], b[1])


def _intersect(a, b, c, d):
    p, q, r, s = _cross(a, b, c), _cross(a, b, d), _cross(c, d, a), _cross(c, d, b)
    return ((p == 0 and _between(a, b, c)) or (q == 0 and _between(a, b, d))
            or (r == 0 and _between(c, d, a)) or (s == 0 and _between(c, d, b))
            or (p * q < 0 and r * s < 0))


def _parse(frame, length, null_input):
    if (type(null_input) is not bool or null_input
            or not isinstance(frame, (list, tuple))
            or not 2 <= len(frame) <= MAX_WORDS
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in frame)
            or length is not None and (type(length) is not int or length != len(frame))):
        return None
    n, c = frame[0], frame[1]
    if type(n) is not int or not 0 <= n <= 8 or type(c) is not int or not 1 <= c <= 46:
        return None
    if len(frame) != 2 + 2 * c + 4 * n:
        return None
    cells = []
    cur = 2
    end_cursor = 0
    for _ in range(c):
        depth, prefix = frame[cur], frame[cur + 1]
        cur += 2
        if type(depth) is not int or not 0 <= depth <= 4:
            return None
        if type(prefix) is not int or prefix < 0 or prefix >= 1 << (2 * depth):
            return None
        length_at_depth = 1 << (2 * (4 - depth))
        left = prefix * length_at_depth
        right = left + length_at_depth
        if left != end_cursor:
            return None
        end_cursor = right
        cells.append((depth, prefix, left, _box(depth, prefix)))
    if end_cursor != 256 or (n == 0 and (c != 1 or cells[0][:2] != (0, 0))):
        return None

    edges = []
    pts = []
    for _ in range(n):
        edge = tuple(frame[cur:cur + 4])
        cur += 4
        if any(not 0 <= v <= 255 or v % 16 == 0 for v in edge):
            return None
        ax, ay, bx, by = edge
        if (ax == bx and ay == by) or ay == by:
            return None
        if ax > bx or ax == bx and ay > by:
            edge = (bx, by, ax, ay)
        edges.append(edge)
        pts.extend((edge[:2], edge[2:]))
    if len(set(pts)) != 2 * n:
        return None
    for i, edge in enumerate(edges):
        a, b = edge[:2], edge[2:]
        for gx in range(0, 257, 16):
            for gy in range(0, 257, 16):
                if _cross(a, b, (gx, gy)) == 0 and _between(a, b, (gx, gy)):
                    return None
        for old in edges[:i]:
            if _intersect(a, b, old[:2], old[2:]):
                return None

    endpoint_cell_counts = [0] * c
    endpoint_cell = []
    for point in pts:
        key = _key4(point)
        found = next((i for i, cell in enumerate(cells)
                      if cell[2] <= key < cell[2] + (1 << (2 * (4 - cell[0])))), None)
        if found is None:
            return None
        endpoint_cell_counts[found] += 1
        endpoint_cell.append(found)
    if any(k > 1 for k in endpoint_cell_counts):
        return None

    # Every explicit split must separate endpoint-bearing child quadrants.
    prefixes = set()
    for depth, prefix, _left, _rect in cells:
        for ancestor_depth in range(depth):
            prefixes.add((ancestor_depth, prefix >> (2 * (depth - ancestor_depth))))
    for parent_depth, parent in prefixes:
        occupied_children = set()
        for i, (depth, prefix, _left, _rect) in enumerate(cells):
            if endpoint_cell_counts[i] == 0 or depth <= parent_depth:
                continue
            if prefix >> (2 * (depth - parent_depth)) == parent:
                occupied_children.add((prefix >> (2 * (depth - parent_depth - 1))) & 3)
        if len(occupied_children) < 2:
            return None

    alternate_cells = []
    for i, (depth, prefix, _left, _rect) in enumerate(cells):
        transformed = 0
        for shift in range(2 * (depth - 1), -1, -2):
            transformed = 4 * transformed + (2, 0, 3, 1)[(prefix >> shift) & 3]
        alternate_cells.append((transformed << (2 * (4 - depth)), i))
    return cells, edges, endpoint_cell, alternate_cells


def _simulate(frame, frame_length=None, input_is_null=False):
    parsed = _parse(frame, frame_length, input_is_null)
    if parsed is None:
        return None
    cells, edges, endpoint_cell, alternate_cells = parsed
    masks = [0] * len(cells)
    for negative in (False, True):
        if negative:
            order = [cell_id for _lo, cell_id in sorted(alternate_cells)]
        else:
            order = list(range(len(cells)))
        rank = {cell_id: i for i, cell_id in enumerate(order)}
        for edge_id, edge in enumerate(edges):
            if (edge[3] < edge[1]) != negative:
                continue
            start = 2 * edge_id
            start_cell, end_cell = endpoint_cell[start], endpoint_cell[start + 1]
            if (rank[start_cell] > rank[end_cell]) != False:
                return None
        # This deliberately checks every pair independently of the sweep state.
        for cell_id, cell in enumerate(cells):
            for edge_id, edge in enumerate(edges):
                if (edge[3] < edge[1]) == negative and _fraction_clip(edge, cell[3]):
                    masks[cell_id] |= 1 << edge_id
    return [len(cells), *masks]


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return BAD, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return NO_OUTPUT, b""
    return len(payload), payload
