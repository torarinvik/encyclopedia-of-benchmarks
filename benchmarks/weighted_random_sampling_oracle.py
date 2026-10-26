"""Exact rational-key oracle for supplied-randomness weighted sampling."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from functools import cmp_to_key

MAX_N = 16
MAX_INPUT = 50
MAX_OUTPUT_BYTES = 128


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 5 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, sample_size = values[:2]
    triples = [values[2 + 3*i:5 + 3*i] for i in range(n)] if 1 <= n <= MAX_N else []
    if not 1 <= n <= MAX_N or not 1 <= sample_size <= n or len(values) != 2 + 3*n:
        return -1, b""
    if any(not 1 <= w <= 3 or not 1 <= numerator < denominator <= 100 for w, numerator, denominator in triples):
        return -1, b""

    def cmp(left: int, right: int) -> int:
        wi, ai, bi = triples[left]
        wj, aj, bj = triples[right]
        lhs = pow(ai, wj) * pow(bj, wi)
        rhs = pow(aj, wi) * pow(bi, wj)
        return -1 if lhs > rhs else 1 if lhs < rhs else (left > right) - (left < right)

    selected = sorted(range(n), key=cmp_to_key(cmp))[:sample_size]
    payload = b"".join(struct.pack("<q", item) for item in selected)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
