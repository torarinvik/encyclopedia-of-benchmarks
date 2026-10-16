"""Oracle for the bounded full-wave rectifier formula-vector contract."""

from __future__ import annotations

import struct

INVALID_RESULT = -1
CAPACITY_ERROR_RESULT = -2
OUTPUT_BYTES = 48
MAX_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_RESISTANCE = 1_000_000
MAX_SIGNAL = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_values(values: list[int] | tuple[int, ...]) -> tuple[float, ...] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None
    rf, rs, rl, vm, im = values
    if (not 0 <= rf <= MAX_RESISTANCE or not 0 <= rs <= MAX_RESISTANCE
            or not 1 <= rl <= MAX_RESISTANCE
            or not -MAX_SIGNAL <= vm <= MAX_SIGNAL
            or not -MAX_SIGNAL <= im <= MAX_SIGNAL):
        return None

    rf_f, rs_f, rl_f, vm_f, im_f = map(float, (rf, rs, rl, vm, im))
    # Preserve the pinned source's multiplication and addition order.
    return (
        vm_f / (rf_f + rs_f + rl_f),
        2.0 * im_f * 0.318,
        2.0 * 0.318 * vm_f,
        vm_f / rl_f,
        im_f * 0.707,
        vm_f * 0.707,
    )


def expected_output(
    values: list[int] | tuple[int, ...], output_capacity: int = OUTPUT_BYTES
) -> tuple[int, bytes]:
    result = expected_values(values)
    if result is None:
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < OUTPUT_BYTES:
        return CAPACITY_ERROR_RESULT, b""
    return OUTPUT_BYTES, struct.pack("<6d", *result)
