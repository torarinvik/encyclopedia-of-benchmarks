"""Finite-tape entropy-recycling reference for a seven-sided die."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DRAWS = 256
MAX_VALID_INPUT_LENGTH = 1 + MAX_DRAWS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_DRAWS
WORKSPACE_BYTES = MAX_OUTPUT_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    draw_count = values[0]
    if not 0 <= draw_count <= MAX_DRAWS or len(values) != draw_count + 1:
        return None
    draws = tuple(values[1:])
    if any(not 0 <= draw <= 4 for draw in draws):
        return None
    return draws


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return 1..7 face bytes generated from the supplied 0..4 draw tape."""
    draws = _parse(values, input_is_null, input_length)
    if draws is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or type(capacity) is not int
            or output_is_null or capacity < 0):
        return OUTPUT_ERROR_RESULT, b""

    value = 0
    state_count = 1
    faces = bytearray()
    for draw in draws:
        value = 5 * value + draw
        state_count *= 5
        while state_count >= 7:
            accepted_states = state_count - state_count % 7
            if value < accepted_states:
                faces.append(value % 7 + 1)
                value //= 7
                state_count = accepted_states // 7
            else:
                value -= accepted_states
                state_count -= accepted_states

    if capacity < len(faces):
        return OUTPUT_ERROR_RESULT, b""
    return len(faces), bytes(faces)
