"""Three-state remainder-DFA reference for the binary divisibility profile."""

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


def _bit_count(values: Sequence[int] | None, input_is_null: bool,
               input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not I64_MIN <= word <= I64_MAX
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if type(count) is not int or not 1 <= count <= MAX_BITS or len(values) != count + 1:
        return None
    if any(bit not in (0, 1) for bit in values[1:]):
        return None
    return count


def expected_output(values: Sequence[int] | None, output_capacity: int = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return (byte count, output) using r <- (2*r + bit) mod 3."""
    count = _bit_count(values, input_is_null, input_length)
    if count is None:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool or type(output_capacity) is not int \
            or output_capacity < 0 or output_is_null or output_capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""

    remainder = 0
    assert values is not None
    for bit in values[1:count + 1]:
        remainder = (2 * remainder + bit) % 3
    return MAX_OUTPUT_BYTES, bytes((1 if remainder == 0 else 0,))


def expected_result(values: Sequence[int] | None, output_capacity: int = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    return expected_output(values, output_capacity, output_is_null,
                           input_is_null, input_length)[0]
