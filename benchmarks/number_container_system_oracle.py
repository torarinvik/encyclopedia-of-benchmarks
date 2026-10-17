"""Oracle for the bounded number-container change/find operation trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 95
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return comma-separated ASCII find results or an ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    if len(values) != 1 + 3 * operation_count:
        return INVALID_RESULT, b""

    values_by_index: dict[int, int] = {}
    answers: list[int] = []
    cursor = 1
    for _ in range(operation_count):
        opcode, first, second = values[cursor : cursor + 3]
        cursor += 3
        if opcode == 0:
            if not 0 <= first <= 63 or not -100 <= second <= 100:
                return INVALID_RESULT, b""
            values_by_index[first] = second
        elif opcode == 1:
            if not -100 <= first <= 100 or second != 0:
                return INVALID_RESULT, b""
            matches = [
                index for index, number in values_by_index.items() if number == first
            ]
            answers.append(min(matches) if matches else -1)
        else:
            return INVALID_RESULT, b""

    encoded = ",".join(str(answer) for answer in answers).encode("ascii")
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
