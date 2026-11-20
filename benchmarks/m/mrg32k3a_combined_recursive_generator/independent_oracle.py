"""Full-history recurrence reference for the bounded MRG32k3a trace."""

from __future__ import annotations

M1 = 4_294_967_087
M2 = 4_294_944_443
MAX_COUNT = 64
MAX_VALID_INPUT = 7
MAX_PARSEABLE_INPUT = 8
MAX_OUTPUT_BYTES = 512
MAX_WORKSPACE_BYTES = 128
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _valid_state(values: list[int]) -> bool:
    if len(values) != 6 or any(type(value) is not int for value in values):
        return False
    return (all(0 <= value < M1 for value in values[:3])
            and all(0 <= value < M2 for value in values[3:])
            and any(values[:3]) and any(values[3:]))


def _trace(state: list[int], count: int) -> list[int]:
    # Separate full histories intentionally avoid the primary's rolling state.
    x1 = state[:3].copy()
    x2 = state[3:].copy()
    while len(x1) < 3 + count:
        x1.append((1_403_580 * x1[-2] - 810_728 * x1[-3]) % M1)
    while len(x2) < 3 + count:
        x2.append((527_612 * x2[-1] - 1_370_589 * x2[-3]) % M2)
    return [(x1[3 + index] - x2[3 + index]) % M1 for index in range(count)]


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    length = len(input_values) if input_length is None else input_length
    if (type(length) is not int or length != len(input_values)
            or length < 1 or length > MAX_PARSEABLE_INPUT):
        return INVALID_RESULT, b""
    if input_is_null or length != MAX_VALID_INPUT:
        return INVALID_RESULT, b""
    if any(type(value) is not int for value in input_values):
        return INVALID_RESULT, b""
    if not _valid_state(input_values[:6]):
        return INVALID_RESULT, b""
    count = input_values[6]
    if not 0 <= count <= MAX_COUNT:
        return INVALID_RESULT, b""
    required = count * 8
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return OUTPUT_ERROR, b""
    if (required > 0 and output_is_null) or (
        output_capacity is not None and output_capacity < required
    ):
        return OUTPUT_ERROR, b""
    if count == 0:
        return 0, b""
    output = b"".join(value.to_bytes(8, "little", signed=True)
                      for value in _trace(input_values[:6], count))
    return len(output), output
