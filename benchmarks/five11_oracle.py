"""Oracle for the bounded BitBench five11 packet decoder."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALID_INPUT_LENGTH = 13_523
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_PACKETS = 451
REPETITIONS = 10_000
MAX_CHANNELS = 31
MAX_CHANNEL_VALUE = 2_047
MAX_RESULT = MAX_PACKETS * MAX_CHANNELS * MAX_CHANNEL_VALUE
INVALID_RESULT = -1


def _read_bits(data: Sequence[int], bit_offset: int, width: int) -> int | None:
    """Read an unsigned, most-significant-bit-first field or report truncation."""
    bit_length = len(data) * 8
    if bit_offset < 0 or bit_offset > bit_length or width > bit_length - bit_offset:
        return None
    value = 0
    for index in range(width):
        absolute = bit_offset + index
        value = (value << 1) | ((data[absolute >> 3] >> (7 - (absolute & 7))) & 1)
    return value


def _decode_sum(data: Sequence[int]) -> int | None:
    packet_count = _read_bits(data, 0, 16)
    if packet_count is None or packet_count > MAX_PACKETS:
        return None
    bit_offset = 16
    total = 0
    for _ in range(packet_count):
        channel_count = _read_bits(data, bit_offset, 5)
        if channel_count is None:
            return None
        bit_offset += 5
        for _ in range(channel_count):
            channel = _read_bits(data, bit_offset, 11)
            if channel is None:
                return None
            total += channel
            bit_offset += 11
        packet_bits = 5 + 11 * channel_count
        bit_offset += (-packet_bits) & 7
        if bit_offset > len(data) * 8:
            return None
    # The source reads the declared records and ignores the rest of its input buffer.
    return total


def expected_result(values: Sequence[int] | None) -> int:
    """Return the source's sum of channel values, or -1 outside the bounded profile."""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not 0 <= value <= 255 for value in values):
        return INVALID_RESULT
    result = _decode_sum(values)
    return INVALID_RESULT if result is None else result
