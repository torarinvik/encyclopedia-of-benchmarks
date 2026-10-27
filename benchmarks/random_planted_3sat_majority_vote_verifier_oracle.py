"""Independent variable-scan verifier for DOI330 majority vote."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 96


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return invalid, b""
    if (not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return invalid, b""
    n, m = values[0], values[1]
    if not 3 <= n <= MAX_VARS or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 3 * m:
        return invalid, b""
    for clause_at in range(2, len(values), 3):
        clause = values[clause_at:clause_at + 3]
        if (any(lit == 0 or abs(lit) > n for lit in clause)
                or len({abs(lit) for lit in clause}) != 3):
            return invalid, b""
    result = []
    for variable in range(1, n + 1):
        plus = sum(1 for lit in values[2:] if lit == variable)
        minus = sum(1 for lit in values[2:] if lit == -variable)
        result.append(1 if plus > minus else -1)
    payload = struct.pack("<" + "q" * n, *result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
