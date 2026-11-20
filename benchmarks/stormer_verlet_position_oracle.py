"""Primary recurrence oracle for position-only Störmer-Verlet integration."""

from __future__ import annotations

from collections.abc import Sequence

MAX_STEPS = 32
MAX_PARSEABLE_INPUT_LENGTH = MAX_STEPS + 1
MAX_OUTPUT_BYTES = 8 * MAX_STEPS
WORKSPACE_BYTES = MAX_OUTPUT_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _positions(values: Sequence[int] | None) -> list[int] | None:
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 3
        or len(values) > MAX_STEPS + 1
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    count = values[0]
    if not 2 <= count <= MAX_STEPS or len(values) != count + 1:
        return None
    if not -1024 <= values[1] <= 1024 or not -1024 <= values[2] <= 1024:
        return None
    if any(not -64 <= term <= 64 for term in values[3:]):
        return None

    positions = [values[1], values[2]]
    for term in values[3:]:
        positions.append(2 * positions[-1] - positions[-2] + term)
    return positions


def _encode(positions: Sequence[int]) -> bytes:
    return b"".join(position.to_bytes(8, byteorder="little", signed=True) for position in positions)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null:
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (tuple, list))
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    positions = _positions(values)
    if positions is None:
        return INVALID_RESULT, b""
    output = _encode(positions)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output


def expected_result(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    return expected_output(values, capacity, input_is_null, output_is_null, input_length)[0]
