"""Independent unpacked-bit verifier for rank1 and select1 queries."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_BITS = 63
MAX_QUERIES = 16
MAX_INPUT = 35


def _parse_record(values: Sequence[int] | None) -> tuple[list[int], list[tuple[int, int]]] | None:
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, packed, q = values[0], values[1], values[2]
    if not 1 <= n <= MAX_BITS or packed < 0 or packed >> n != 0:
        return None
    if not 0 <= q <= MAX_QUERIES or len(values) != 3 + 2 * q:
        return None
    bits = [int((packed >> position) & 1) for position in range(n)]
    calls = []
    for pos in range(3, len(values), 2):
        op, rank = values[pos], values[pos + 1]
        if op == 0 and not 1 <= rank <= n or op == 1 and not 1 <= rank <= MAX_BITS + 1:
            return None
        if op not in (0, 1):
            return None
        calls.append((op, rank))
    return bits, calls


def _evaluate(bits: list[int], calls: list[tuple[int, int]]) -> list[int]:
    answers = []
    ones = [position + 1 for position, bit in enumerate(bits) if bit]
    for op, rank in calls:
        if op == 0:
            answers.append(sum(bits[:rank]))
        else:
            answers.append(ones[rank - 1] if rank <= len(ones) else -1)
    return answers


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse_record(values)
    if parsed is None:
        return -1, b""
    bits, queries = parsed
    payload = b"".join(struct.pack("<q", answer) for answer in _evaluate(bits, queries))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
