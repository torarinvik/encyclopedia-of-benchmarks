"""Primary exact-reference replay for asymmetric-proposal Metropolis-Hastings."""

from __future__ import annotations

from collections.abc import Sequence

MAX_STATES = 8
MAX_STEPS = 64
MAX_INPUT_LENGTH = 267
MAX_PARSEABLE_INPUT_LENGTH = 268
MAX_OUTPUT_BYTES = 65
WORKSPACE_BYTES = 65
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _trace(values: Sequence[int] | None) -> bytes | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    states, steps, initial = values[:3]
    if not (2 <= states <= MAX_STATES and 0 <= steps <= MAX_STEPS and 0 <= initial < states):
        return None
    if len(values) != 3 + states + states * states + 3 * steps:
        return None

    weights_start = 3
    proposal_matrix_start = weights_start + states
    proposal_tape_start = proposal_matrix_start + states * states
    draw_tape_start = proposal_tape_start + steps
    weights = values[weights_start:proposal_matrix_start]
    matrix = values[proposal_matrix_start:proposal_tape_start]
    if any(not 1 <= weight <= 1024 for weight in weights):
        return None
    for source in range(states):
        row = matrix[source * states : (source + 1) * states]
        if any(not 0 <= weight <= 1024 for weight in row) or sum(row) != 1024:
            return None

    current = initial
    trace = bytearray((current,))
    for step in range(steps):
        proposal = values[proposal_tape_start + step]
        draw_num = values[draw_tape_start + 2 * step]
        draw_den = values[draw_tape_start + 2 * step + 1]
        if not 0 <= proposal < states or matrix[current * states + proposal] == 0:
            return None
        if not (1 <= draw_den <= 1024 and 0 <= draw_num < draw_den):
            return None

        numerator = weights[proposal] * matrix[proposal * states + current]
        denominator = weights[current] * matrix[current * states + proposal]
        if numerator >= denominator or draw_num * denominator < draw_den * numerator:
            current = proposal
        trace.append(current)
    return bytes(trace)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (tuple, list))
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    trace = _trace(values)
    if trace is None:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(trace)):
        return OUTPUT_ERROR, b""
    return len(trace), trace


def expected_result(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    return expected_output(values, capacity, output_is_null, input_is_null, input_length)[0]


oracle = expected_output
