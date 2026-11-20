"""Alternating-sign identity reference, independent of the DFA transition."""

from __future__ import annotations

from collections.abc import Sequence

MAX_BITS = 4096
MAX_VALID_INPUT_LENGTH = MAX_BITS + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_BITS + 2
MAX_OUTPUT_BYTES = 1
MAX_WORKSPACE_BYTES = 64
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _valid(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> bool:
    if type(input_is_null) is not bool or input_is_null:
        return False
    if not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return False
    if any(type(word) is not int or word < I64_MIN or word > I64_MAX for word in values):
        return False
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return False
    count = values[0]
    if not 1 <= count <= MAX_BITS or len(values) != count + 1:
        return False
    return all(bit == 0 or bit == 1 for bit in values[1:])


def expected_output(values: Sequence[int] | None, output_capacity: int = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Use 2**k == (-1)**k (mod 3) to test the represented value."""
    if not _valid(values, input_is_null, input_length):
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool or type(output_capacity) is not int \
            or output_capacity < 0 or output_is_null or output_capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""

    assert values is not None
    count = values[0]
    alternating_sum = 0
    for index, bit in enumerate(values[1:count + 1]):
        exponent = count - 1 - index
        alternating_sum += bit if exponent % 2 == 0 else -bit
    return MAX_OUTPUT_BYTES, bytes((1 if alternating_sum % 3 == 0 else 0,))


def expected_result(values: Sequence[int] | None, output_capacity: int = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    return expected_output(values, output_capacity, output_is_null,
                           input_is_null, input_length)[0]
