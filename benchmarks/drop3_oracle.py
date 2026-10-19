"""Oracle for the bounded BitBench drop3 bitstream filter."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALID_INPUT_LENGTH = 4096
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
ITERATIONS = 20
INVALID_RESULT = -1
_OFFSETS = (0, 5, 2, 7, 4, 1, 6, 3)


def _one_pass(values: Sequence[int]) -> int:
    """Return the byte count produced by one source-order filtering pass."""
    input_index = 0
    remaining_bits = len(values) * 8
    phase = 0
    bit_buffer = 0
    output_bits = 0
    while remaining_bits >= 3:
        remaining_bits -= 3
        offset = _OFFSETS[phase]
        if offset < 3:
            bit_buffer |= values[input_index] << (8 - offset)
            input_index += 1
        code = (bit_buffer >> 13) & 7
        if code >= 4:
            output_bits += 3
        bit_buffer = (bit_buffer << 3) & 0xFFFF
        phase = (phase + 1) & 7
    return output_bits >> 3


def expected_result(values: Sequence[int] | None) -> int:
    """Mirror drop3's 20 repeated passes and return the final output byte count."""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not 0 <= value <= 255 for value in values):
        return INVALID_RESULT
    if len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT

    output_size = 0
    for _ in range(ITERATIONS):
        output_size = _one_pass(values)
    return output_size
