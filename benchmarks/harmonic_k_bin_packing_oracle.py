"""Bounded HARM(k): exact reciprocal classes with class-local Next Fit."""
from __future__ import annotations
import struct
from collections.abc import Sequence

MAX_K = 8
MIN_K = 3
MAX_N = 32
MAX_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 34
CAPACITY = 10_000
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)


def _pack(values: Sequence[int]) -> bytes:
    return b"".join(struct.pack("<q", int(value)) for value in values)


def _class(size: int, k: int) -> int:
    # Class i (zero based) represents (1/(i+2), 1/(i+1)] for
    # i=0..k-2; the final class represents (0,1/k].
    for i in range(k - 1):
        if size * (i + 2) > CAPACITY:
            return i
    return k - 1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH or any(
            type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return -1, b""
    k, n = values[0], values[1]
    sizes = values[2:]
    if not MIN_K <= k <= MAX_K or not 1 <= n <= MAX_N or len(sizes) != n or any(not 1 <= s <= CAPACITY for s in sizes):
        return -1, b""
    current = [-1] * k
    remaining = [0] * k
    assignments: list[int] = []
    bin_count = 0
    for size in sizes:
        kind = _class(size, k)
        if current[kind] < 0 or size > remaining[kind]:
            current[kind] = bin_count
            bin_count += 1
            remaining[kind] = CAPACITY
        assignments.append(current[kind])
        remaining[kind] -= size
    output = _pack((bin_count, *assignments))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
