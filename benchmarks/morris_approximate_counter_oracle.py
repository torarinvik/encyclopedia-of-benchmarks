"""Independent integer-tape replay oracle for Morris approximate counting."""

import struct

MAX_UPDATES = 53
DRAW_BITS = 53
DRAW_LIMIT = 1 << DRAW_BITS
MAX_PARSEABLE_INPUT_LENGTH = 1 + MAX_UPDATES
MAX_OUTPUT_BYTES = 16


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[Q, draw_0, ..., draw_(Q-1)]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int for value in values)):
        return -1, b""
    updates = values[0]
    if not 1 <= updates <= MAX_UPDATES or len(values) != 1 + updates:
        return -1, b""
    draws = values[1:]
    if any(draw < 0 or draw >= DRAW_LIMIT for draw in draws):
        return -1, b""

    state = 0
    for draw in draws:
        # Compare the represented uniform fraction with 2^-state by
        # cross-multiplication, independent of the ports' shifted threshold.
        if draw * (1 << state) < DRAW_LIMIT:
            state += 1
    estimate = (1 << state) - 1
    encoded = struct.pack("<qq", state, estimate)

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return MAX_OUTPUT_BYTES, encoded
