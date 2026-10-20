"""Reference semantics for bounded batched updates and nearest queries."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_POINTS = 32
MAX_INITIAL = 8
MAX_BATCHES = 8
MAX_BATCH_SIZE = 8
MAX_INPUT = 250
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * MAX_BATCHES
COORD_MIN = -1000
COORD_MAX = 1000


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_INPUT
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return -1, b""
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return -1, b""
    initial_n = values[0]
    if not 0 <= initial_n <= MAX_INITIAL or len(values) < 1 + 3 * initial_n + 1:
        return -1, b""
    pos = 1
    points: dict[int, tuple[int, int]] = {}
    active: set[int] = set()
    ever_ids: set[int] = set()

    def valid_coord(x: int, y: int) -> bool:
        return COORD_MIN <= x <= COORD_MAX and COORD_MIN <= y <= COORD_MAX

    def has_active_coord(x: int, y: int) -> bool:
        return any(points[pid] == (x, y) for pid in active)

    for _ in range(initial_n):
        pid, x, y = values[pos:pos + 3]
        pos += 3
        if not 0 <= pid < MAX_POINTS or not valid_coord(x, y) or pid in ever_ids or has_active_coord(x, y):
            return -1, b""
        points[pid] = (x, y)
        active.add(pid)
        ever_ids.add(pid)
    if pos >= len(values):
        return -1, b""
    batch_count = values[pos]
    pos += 1
    if not 1 <= batch_count <= MAX_BATCHES:
        return -1, b""
    results: list[int] = []
    for _ in range(batch_count):
        if pos + 2 > len(values):
            return -1, b""
        kind, count = values[pos], values[pos + 1]
        pos += 2
        if kind not in (0, 1) or not 1 <= count <= MAX_BATCH_SIZE:
            return -1, b""
        if kind == 0:
            if pos + 3 * count + 2 > len(values) or len(ever_ids) + count > MAX_POINTS:
                return -1, b""
            pending: list[tuple[int, int, int]] = []
            pending_ids: set[int] = set()
            pending_points: set[tuple[int, int]] = set()
            for j in range(count):
                pid, x, y = values[pos + 3*j:pos + 3*j + 3]
                if (not 0 <= pid < MAX_POINTS or pid in ever_ids or pid in pending_ids
                        or not valid_coord(x, y) or (x, y) in pending_points or has_active_coord(x, y)):
                    return -1, b""
                pending.append((pid, x, y))
                pending_ids.add(pid)
                pending_points.add((x, y))
            pos += 3 * count
            for pid, x, y in pending:
                points[pid] = (x, y)
                active.add(pid)
                ever_ids.add(pid)
        else:
            if pos + count + 2 > len(values):
                return -1, b""
            deleting = values[pos:pos + count]
            if len(set(deleting)) != count or any(pid not in active for pid in deleting):
                return -1, b""
            for pid in deleting:
                active.remove(pid)
            pos += count
        qx, qy = values[pos:pos + 2]
        pos += 2
        if not valid_coord(qx, qy) or not active:
            return -1, b""
        results.append(min((points[pid][0] - qx) ** 2 + (points[pid][1] - qy) ** 2 for pid in active))
    if pos != len(values):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    needed = 8 * batch_count
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return -2, b""
    return needed, struct.pack("<" + "q" * batch_count, *results)
