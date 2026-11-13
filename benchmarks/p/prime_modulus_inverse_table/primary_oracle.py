"""Linear prime-modulus inverse table oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_QUERIES = 32
MAX_VALUE = 256
MAX_VALID_INPUT_LENGTH = MAX_QUERIES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_QUERIES * 4
WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    query_count = values[0]
    if not 0 <= query_count <= MAX_QUERIES or len(values) != query_count + 1:
        return None
    operands = tuple(values[1:])
    if any(not 1 <= value <= MAX_VALUE for value in operands):
        return None
    return query_count, operands


def _inverse_table(maximum: int) -> list[int]:
    inverses = [0] * (maximum + 1)
    if maximum:
        inverses[1] = 1
    for value in range(2, maximum + 1):
        inverses[value] = MODULUS - (MODULUS // value) * inverses[MODULUS % value] % MODULUS
    return inverses


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    query_count, operands = parsed
    if query_count == 0:
        return 0, b""
    if type(output_is_null) is not bool:
        return CAPACITY_ERROR, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    required = 4 * query_count
    if (type(effective_capacity) is not int or effective_capacity < 0
            or output_is_null or effective_capacity < required):
        return CAPACITY_ERROR, b""
    inverses = _inverse_table(max(operands))
    payload = b"".join(struct.pack("<I", inverses[value]) for value in operands)
    return len(payload), payload


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
