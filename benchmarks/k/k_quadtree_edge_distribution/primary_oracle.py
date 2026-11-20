"""Bounded slope-ordered K-quadtree edge-distribution sweep."""

from __future__ import annotations

import struct
from fractions import Fraction

MAX_EDGES = 8
MAX_DEPTH = 4
MAX_CELLS = 46
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_CELLS + 4 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + MAX_CELLS)
WORKSPACE_BYTES = 16384
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _z_key(x: int, y: int, alternate: bool = False) -> int:
    """Return the depth-four base-4 key in the selected source quadrant order."""
    key = 0
    for bit in range(7, 3, -1):
        quadrant = (((x >> bit) & 1) << 1) | ((y >> bit) & 1)
        if alternate:
            # Source Z' order is NW, NE, SW, SE.
            quadrant = (2, 0, 3, 1)[quadrant]
        key = (key << 2) | quadrant
    return key


def _alternate_prefix(depth: int, prefix: int) -> int:
    digits = []
    for shift in range(2 * (depth - 1), -1, -2):
        digits.append((prefix >> shift) & 3)
    result = 0
    for quadrant in digits:
        result = (result << 2) | (2, 0, 3, 1)[quadrant]
    return result


def _cell_box(depth: int, prefix: int) -> tuple[int, int, int, int]:
    x_index = 0
    y_index = 0
    for shift in range(2 * (depth - 1), -1, -2):
        quadrant = (prefix >> shift) & 3
        x_index = (x_index << 1) | (quadrant >> 1)
        y_index = (y_index << 1) | (quadrant & 1)
    side = 256 >> depth
    x0 = x_index * side
    y0 = y_index * side
    return x0, y0, x0 + side, y0 + side


def _orient(a, b, c) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _on_segment(a, b, p) -> bool:
    return (min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _segments_intersect(a, b, c, d) -> bool:
    o1 = _orient(a, b, c)
    o2 = _orient(a, b, d)
    o3 = _orient(c, d, a)
    o4 = _orient(c, d, b)
    if o1 == 0 and _on_segment(a, b, c):
        return True
    if o2 == 0 and _on_segment(a, b, d):
        return True
    if o3 == 0 and _on_segment(c, d, a):
        return True
    if o4 == 0 and _on_segment(c, d, b):
        return True
    return o1 * o2 < 0 and o3 * o4 < 0


def _segment_hits_box(edge, box) -> bool:
    x0, y0, x1, y1 = box
    a = edge[0], edge[1]
    b = edge[2], edge[3]
    if x0 <= a[0] <= x1 and y0 <= a[1] <= y1:
        return True
    if x0 <= b[0] <= x1 and y0 <= b[1] <= y1:
        return True
    corners = ((x0, y0), (x1, y0), (x1, y1), (x0, y1))
    return any(_segments_intersect(a, b, corners[i], corners[(i + 1) & 3])
               for i in range(4))


def _sweep_box(cell, alternate):
    x0, y0, x1, y1 = cell["box"]
    if alternate:
        return 256 - y1, x0, 256 - y0, x1
    return x0, y0, x1, y1


def _sweep_edge(edge, alternate):
    x0, y0, x1, y1 = edge
    if alternate:
        return 256 - y0, x0, 256 - y1, x1
    return edge


def _frontier_path(cells, order, cut, alternate):
    """Build the finite-depth staircase for the first `cut` Morton leaves.

    The 16-by-16 depth-four atoms induce a down-closed column profile. Its
    boundary is the monotone path from the square's upper-left to lower-right
    corner; the perimeter portions extend the source frontier to the left and
    bottom edges without adding any edge crossings (all inputs are interior).
    """
    atom_cell = [-1] * 256
    for cell_id in order:
        cell = cells[cell_id]
        start = cell["alternate_lo"] if alternate else cell["lo"]
        span = 1 << (2 * (MAX_DEPTH - cell["depth"]))
        for key in range(start, start + span):
            atom_cell[key] = cell_id
    rank = {cell_id: i for i, cell_id in enumerate(order)}
    processed = [[False] * 16 for _ in range(16)]
    for key, cell_id in enumerate(atom_cell):
        if cell_id < 0:
            return None
        x = y = 0
        for shift in (6, 4, 2, 0):
            digit = (key >> shift) & 3
            x = (x << 1) | (digit >> 1)
            y = (y << 1) | (digit & 1)
        processed[x][y] = rank[cell_id] < cut

    heights = []
    for x in range(16):
        height = 0
        while height < 16 and processed[x][height]:
            height += 1
        if any(processed[x][y] != (y < height) for y in range(16)):
            return None
        heights.append(height)
    if any(heights[i] < heights[i + 1] for i in range(15)):
        return None

    points = [(0, 16)]

    def append(point):
        if points[-1] != point:
            points.append(point)

    for y in range(15, heights[0] - 1, -1):
        append((0, y))
    for x in range(16):
        append((x + 1, heights[x]))
        next_height = heights[x + 1] if x < 15 else 0
        for y in range(heights[x] - 1, next_height - 1, -1):
            append((x + 1, y))
    path = [(16 * x, 16 * y) for x, y in points]
    if path[0] != (0, 256) or path[-1] != (256, 0):
        return None
    next_box = _sweep_box(cells[order[cut]], alternate)
    lower_left = (next_box[0], next_box[1])
    try:
        lower_left_index = path.index(lower_left)
    except ValueError:
        return None
    return path, lower_left_index


def _edge_frontier_segment(edge, path):
    a = edge[0], edge[1]
    b = edge[2], edge[3]
    found = None
    for i in range(len(path) - 1):
        if _segments_intersect(a, b, path[i], path[i + 1]):
            if found is not None:
                return None
            found = i
    return found


def _exit_from_box(edge, box):
    """Return (top-or-right, exact boundary coordinate) for a continuing edge."""
    x0, y0, x1, y1 = box
    ax, ay, bx, by = edge
    dx, dy = bx - ax, by - ay
    candidates = []
    if dy > 0:
        t = Fraction(y1 - ay, dy)
        x_at = Fraction(ax, 1) + t * dx
        if 0 < t < 1 and x0 < x_at < x1:
            candidates.append((0, x_at))
    if dx > 0:
        t = Fraction(x1 - ax, dx)
        y_at = Fraction(ay, 1) + t * dy
        if 0 < t < 1 and y0 < y_at < y1:
            candidates.append((1, y_at))
    if len(candidates) != 1:
        return None
    return candidates[0]


def _parse(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, cell_count = values[:2]
    if type(n) is not int or not 0 <= n <= MAX_EDGES:
        return None
    if type(cell_count) is not int or not 1 <= cell_count <= MAX_CELLS:
        return None
    if len(values) != 2 + 2 * cell_count + 4 * n:
        return None

    cells = []
    cursor = 2
    previous_hi = 0
    for _ in range(cell_count):
        depth, prefix = values[cursor:cursor + 2]
        cursor += 2
        if type(depth) is not int or not 0 <= depth <= MAX_DEPTH:
            return None
        if type(prefix) is not int or not 0 <= prefix < (1 << (2 * depth)):
            return None
        span = 1 << (2 * (MAX_DEPTH - depth))
        lo = prefix * span
        hi = lo + span
        if lo != previous_hi:
            return None
        previous_hi = hi
        cells.append({"depth": depth, "prefix": prefix, "lo": lo,
                      "box": _cell_box(depth, prefix), "alternate_lo": None})
    if previous_hi != 1 << (2 * MAX_DEPTH):
        return None
    if any((cells[i]["lo"], cells[i]["depth"]) > (cells[i + 1]["lo"], cells[i + 1]["depth"])
           for i in range(cell_count - 1)):
        return None
    if n == 0 and (cell_count != 1 or cells[0]["depth"] != 0 or cells[0]["prefix"] != 0):
        return None

    edges = []
    endpoints = []
    for edge_id in range(n):
        x1, y1, x2, y2 = values[cursor:cursor + 4]
        cursor += 4
        if not all(type(v) is int and 0 <= v <= 255 and v % 16 != 0 for v in (x1, y1, x2, y2)):
            return None
        if x1 == x2 and y1 == y2:
            return None
        if y1 == y2:
            return None
        if x1 > x2 or (x1 == x2 and y1 > y2):
            x1, y1, x2, y2 = x2, y2, x1, y1
        edge = (x1, y1, x2, y2)
        if (x1 == x2 and y2 <= y1) or (x1 != x2 and x2 <= x1):
            return None
        edges.append(edge)
        endpoints.extend(((x1, y1), (x2, y2)))
    if len(set(endpoints)) != len(endpoints):
        return None

    for i, edge in enumerate(edges):
        a = edge[0], edge[1]
        b = edge[2], edge[3]
        for gx in range(0, 257, 16):
            for gy in range(0, 257, 16):
                p = (gx, gy)
                if _orient(a, b, p) == 0 and _on_segment(a, b, p):
                    return None
        for other in edges[:i]:
            if _segments_intersect(a, b, (other[0], other[1]), (other[2], other[3])):
                return None

    point_keys = [[_z_key(x, y) for x, y in (edge[:2], edge[2:])] for edge in edges]
    endpoint_cells = []
    endpoint_cell_counts = [0] * cell_count
    for edge_keys in point_keys:
        mapped = []
        for key in edge_keys:
            found = next((i for i, cell in enumerate(cells) if cell["lo"] <= key < cell["lo"] + (1 << (2 * (MAX_DEPTH - cell["depth"])))), None)
            if found is None:
                return None
            mapped.append(found)
            endpoint_cell_counts[found] += 1
        endpoint_cells.append(tuple(mapped))
    if any(count > 1 for count in endpoint_cell_counts):
        return None

    internal = set()
    for cell in cells:
        depth, prefix = cell["depth"], cell["prefix"]
        for parent_depth in range(depth):
            internal.add((parent_depth, prefix >> (2 * (depth - parent_depth))))
    for depth, prefix in internal:
        occupied = set()
        for i, cell in enumerate(cells):
            if endpoint_cell_counts[i] == 0 or cell["depth"] <= depth:
                continue
            if cell["prefix"] >> (2 * (cell["depth"] - depth)) == prefix:
                child = (cell["prefix"] >> (2 * (cell["depth"] - depth - 1))) & 3
                occupied.add(child)
        if len(occupied) < 2:
            return None

    for cell in cells:
        cell["alternate_lo"] = _alternate_prefix(cell["depth"], cell["prefix"]) << (2 * (MAX_DEPTH - cell["depth"]))
    for alternate in (False, True):
        order = list(range(cell_count))
        if alternate:
            order.sort(key=lambda i: (cells[i]["alternate_lo"], cells[i]["depth"], i))
        rank = {cell_id: position for position, cell_id in enumerate(order)}
        for edge_id, (start_cell, end_cell) in enumerate(endpoint_cells):
            if (edges[edge_id][3] < edges[edge_id][1]) != alternate:
                continue
            if rank[start_cell] > rank[end_cell]:
                return None

    return cells, edges, endpoint_cells


def _simulate(values, input_length=None, input_is_null=False):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return None
    cells, edges, endpoint_cells = parsed
    masks = [0] * len(cells)

    for alternate in (False, True):
        order = list(range(len(cells)))
        if alternate:
            order.sort(key=lambda i: (cells[i]["alternate_lo"], cells[i]["depth"], i))
        rank = {cell_id: position for position, cell_id in enumerate(order)}
        direction_edges = []
        for edge_id, edge in enumerate(edges):
            dy = edge[3] - edge[1]
            is_alternate = dy < 0
            if is_alternate == alternate:
                sweep_edge = _sweep_edge(edge, alternate)
                start_key = _z_key(sweep_edge[0], sweep_edge[1])
                direction_edges.append((start_key, edge_id, endpoint_cells[edge_id], sweep_edge))
        direction_edges.sort(key=lambda item: (item[0], item[1]))
        starts = {cell_id: [] for cell_id in order}
        sweep_edges = {}
        for _key, edge_id, (start_cell, _end_cell), sweep_edge in direction_edges:
            starts[start_cell].append(edge_id)
            sweep_edges[edge_id] = sweep_edge

        left_stack = []
        bottom_stack = []
        for position, cell_id in enumerate(order):
            box = _sweep_box(cells[cell_id], alternate)
            incoming = []
            while left_stack and _segment_hits_box(sweep_edges[left_stack[-1]], box):
                incoming.append(left_stack.pop())
            while bottom_stack and _segment_hits_box(sweep_edges[bottom_stack[-1]], box):
                incoming.append(bottom_stack.pop())
            candidates = incoming + starts[cell_id]
            left_exits = []
            bottom_exits = []
            for edge_id in candidates:
                masks[cell_id] |= 1 << edge_id
                if endpoint_cells[edge_id][1] == cell_id:
                    continue
                exit_data = _exit_from_box(sweep_edges[edge_id], box)
                if exit_data is None:
                    return None
                side, coordinate = exit_data
                if side == 0:
                    left_exits.append((coordinate, edge_id))
                else:
                    bottom_exits.append((coordinate, edge_id))
            left_stack.extend(edge_id for _coordinate, edge_id in sorted(left_exits))
            bottom_stack.extend(edge_id for _coordinate, edge_id in sorted(bottom_exits))

            if position + 1 == len(order):
                continue
            frontier = _frontier_path(cells, order, position + 1, alternate)
            if frontier is None:
                return None
            path, corner_index = frontier
            next_box = _sweep_box(cells[order[position + 1]], alternate)
            current_box = box
            if next_box[1] > current_box[1]:
                while left_stack:
                    crossing = _edge_frontier_segment(sweep_edges[left_stack[-1]], path)
                    if crossing is None:
                        return None
                    if crossing < corner_index:
                        break
                    bottom_stack.append(left_stack.pop())
            else:
                while bottom_stack:
                    crossing = _edge_frontier_segment(sweep_edges[bottom_stack[-1]], path)
                    if crossing is None:
                        return None
                    if crossing >= corner_index:
                        break
                    left_stack.append(bottom_stack.pop())
        if left_stack or bottom_stack:
            return None
    return [len(cells), *masks]


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
