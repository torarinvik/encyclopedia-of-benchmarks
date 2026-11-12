"""Independent slice-reconstruction oracle for workload verification."""

from __future__ import annotations

import struct

MOD = 998_244_353


def expected_output(values: list[int] | tuple[int, ...] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > 195
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= 195))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, q = values[0], values[1]
    if not 0 <= n <= 32 or not 0 <= q <= 32 or len(values) < 2 + n:
        return -1, b""
    seq = values[2:2 + n]
    if any(not 0 <= x < MOD for x in seq):
        return -1, b""
    pos = 2 + n
    operations: list[tuple[int, ...]] = []
    length = len(seq)
    queries = 0
    for _ in range(q):
        if pos >= len(values):
            return -1, b""
        tag = values[pos]
        widths = (3, 2, 3, 5, 3)
        if not 0 <= tag < len(widths):
            return -1, b""
        width = widths[tag]
        if pos + width > len(values):
            return -1, b""
        op = tuple(values[pos:pos + width])
        pos += width
        if tag == 0:
            _, at, value = op
            if not 0 <= at <= length or length == 64 or not 0 <= value < MOD:
                return -1, b""
            length += 1
        elif tag == 1:
            _, at = op
            if not 0 <= at < length:
                return -1, b""
            length -= 1
        else:
            _, left, right = op[:3]
            if not 0 <= left <= right <= length:
                return -1, b""
            if tag == 3 and any(not 0 <= x < MOD for x in op[3:]):
                return -1, b""
            if tag == 4:
                queries += 1
        operations.append(op)
    if pos != len(values):
        return -1, b""
    needed = queries * 8
    effective_capacity = 256 if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null or effective_capacity < needed):
        return -2, b""
    answers: list[int] = []
    for op in operations:
        tag = op[0]
        if tag == 0:
            _, at, value = op
            seq = seq[:at] + [value] + seq[at:]
        elif tag == 1:
            at = op[1]
            seq = seq[:at] + seq[at + 1:]
        elif tag == 2:
            _, left, right = op
            seq = seq[:left] + seq[left:right][::-1] + seq[right:]
        elif tag == 3:
            _, left, right, mul, add = op
            part = [(mul * x + add) % MOD for x in seq[left:right]]
            seq = seq[:left] + part + seq[right:]
        else:
            _, left, right = op
            answers.append(sum(seq[left:right]) % MOD)
    data = b"".join(struct.pack("<q", x) for x in answers)
    return len(data), data
