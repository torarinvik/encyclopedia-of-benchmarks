"""Independent per-window polynomial division for content-defined chunks."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 64
POLYNOMIAL = 0x1100B
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or values is None or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if (input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_INPUT_LENGTH
                 or input_length != len(values))):
        return None
    n = values[0]
    if (not 0 <= n <= MAX_OUTPUT_BYTES or len(values) != n + 1
            or any(not 0 <= value <= 255 for value in values[1:])):
        return None
    return tuple(values[1:])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Recompute every suffix window independently, then apply output framing."""
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    payload = _parse(values, input_is_null, input_length)
    if payload is None:
        return -1, b""

    boundaries = bytearray()
    for end in range(1, len(payload) + 1):
        fingerprint = 0
        for byte in payload[max(0, end - 4):end]:
            fingerprint = (fingerprint << 8) | byte
        for degree in range(31, 15, -1):
            if fingerprint & (1 << degree):
                fingerprint ^= POLYNOMIAL << (degree - 16)
        if fingerprint & 7 == 0:
            boundaries.append(end)
    if payload and (not boundaries or boundaries[-1] != len(payload)):
        boundaries.append(len(payload))

    if output_is_null or capacity is not None and capacity < len(boundaries):
        return -2, b""
    return len(boundaries), bytes(boundaries)
