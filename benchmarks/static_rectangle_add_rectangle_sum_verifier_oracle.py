"""Independent compressed-cell scan for static rectangle updates and queries."""

import struct
from typing import Sequence

MAX_N = 32
MAX_Q = 32
MAX_COORD = 1_000_000
MOD = 998_244_353
MAX_VALID_INPUT_LENGTH = 2 + 5 * MAX_N + 4 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_Q * 8


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + 5*n + 4*q:
        return -1, b""
    updates = []
    offset = 2
    xs, ys = set(), set()
    for _ in range(n):
        l, d, r, u, w = values[offset:offset + 5]
        offset += 5
        if not (0 <= l < r <= MAX_COORD and 0 <= d < u <= MAX_COORD and 0 <= w < MOD):
            return -1, b""
        updates.append((l, d, r, u, w))
        xs.update((l, r)); ys.update((d, u))
    queries = []
    for _ in range(q):
        l, d, r, u = values[offset:offset + 4]
        offset += 4
        if not (0 <= l < r <= MAX_COORD and 0 <= d < u <= MAX_COORD):
            return -1, b""
        queries.append((l, d, r, u))
        xs.update((l, r)); ys.update((d, u))

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < 8*q:
        return -2, b""

    x_bounds, y_bounds = sorted(xs), sorted(ys)
    answers = []
    for ql, qd, qr, qu in queries:
        total = 0
        for x0, x1 in zip(x_bounds, x_bounds[1:]):
            if x0 < ql or x1 > qr:
                continue
            for y0, y1 in zip(y_bounds, y_bounds[1:]):
                if y0 < qd or y1 > qu:
                    continue
                cell_value = 0
                for l, d, r, u, w in updates:
                    if l <= x0 and x1 <= r and d <= y0 and y1 <= u:
                        cell_value += w
                area_mod = ((x1 - x0) % MOD) * ((y1 - y0) % MOD) % MOD
                total = (total + (cell_value % MOD) * area_mod) % MOD
        answers.append(total)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
