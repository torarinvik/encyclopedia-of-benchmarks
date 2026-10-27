"""Bounded oracle for the chapter's elementary universal integer-sequence codes."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 512


class _Bits:
    def __init__(self) -> None:
        self.data = bytearray()

    def bit(self, value: int) -> None:
        self.data.append(49 if value else 48)

    def number(self, value: int, width: int) -> None:
        for shift in range(width - 1, -1, -1):
            self.bit((value >> shift) & 1)

    def unary(self, value: int) -> None:
        self.data.extend(b"1" * value)
        self.bit(0)


def _floor_log2(value: int) -> int:
    return value.bit_length() - 1


def _minimal_binary(bits: _Bits, value: int, universe: int) -> None:
    if universe == 1:
        return
    low_width = _floor_log2(universe)
    short_count = (1 << (low_width + 1)) - universe
    if value < short_count:
        bits.number(value, low_width)
    else:
        bits.number(value + short_count, low_width + 1)


def _gamma(bits: _Bits, value: int) -> None:
    shifted = value + 1
    width = _floor_log2(shifted)
    bits.unary(width)
    bits.number(shifted - (1 << width), width)


def _delta(bits: _Bits, value: int) -> None:
    shifted = value + 1
    width = _floor_log2(shifted)
    _gamma(bits, width)
    bits.number(shifted - (1 << width), width)


def _interpolative(bits: _Bits, values: Sequence[int], left: int, right: int,
                   low: int, high: int) -> None:
    if left >= right:
        return
    middle = left + (right - left - 1) // 2
    value = values[middle]
    lower = low + middle - left
    upper = high - (right - middle - 1)
    _minimal_binary(bits, value - lower, upper - lower)
    _interpolative(bits, values, left, middle, low, value)
    _interpolative(bits, values, middle + 1, right, value + 1, high)


def _simple9(values: Sequence[int]) -> bytes:
    selectors = [(28, 1), (14, 2), (9, 3), (7, 4), (5, 5),
                 (4, 7), (3, 9), (2, 14), (1, 28)]
    bits = _Bits()
    position = 0
    while position < len(values):
        selector = -1
        count = 0
        width = 0
        for index, (slots, field_width) in enumerate(selectors):
            take = min(slots, len(values) - position)
            if all(value < (1 << field_width) for value in values[position:position + take]):
                selector, count, width = index, take, field_width
                break
        if selector < 0:
            raise AssertionError("validated value did not fit a Simple-9 selector")
        word = selector << 28
        slots, _ = selectors[selector]
        for offset in range(count):
            shift = 28 - width * (offset + 1)
            word |= values[position + offset] << shift
        bits.number(word, 32)
        position += count
    return bytes(bits.data)


def _pack_ascii_bits(ascii_bits: bytes | bytearray) -> bytes:
    packed = bytearray((len(ascii_bits) + 7) // 8)
    for index, bit in enumerate(ascii_bits):
        if bit == 49:
            packed[index // 8] |= 1 << (7 - index % 8)
    return bytes(packed)


def _validate(values: Sequence[int] | None) -> tuple[int, int, int, list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    mode, count, parameter = values[:3]
    if mode not in range(10) or not 1 <= count <= 32 or len(values) != count + 3:
        return None
    sequence = list(values[3:])
    if mode == 0:
        if parameter != 0 or any(not 0 <= x <= 31 for x in sequence):
            return None
    elif mode == 1:
        if not 2 <= parameter <= 1_000_000 or any(not 0 <= x < parameter for x in sequence):
            return None
    elif mode in (2, 3):
        if parameter != 0 or any(not 0 <= x <= 1_000_000 for x in sequence):
            return None
    elif mode == 4:
        if not 1 <= parameter <= 128 or any(not 0 <= x <= 127 for x in sequence):
            return None
    elif mode == 7:
        if parameter != 0 or any(not 0 <= x <= 1_000_000 for x in sequence):
            return None
    elif mode == 8:
        if parameter != 0 or any(not 0 <= x < (1 << 28) for x in sequence):
            return None
    elif mode == 9:
        if not 1 <= parameter <= 20 or any(not 0 <= x <= 1_000_000 for x in sequence):
            return None
    else:
        if (not 2 <= parameter <= 4096 or count > parameter
                or any(not 0 <= x < parameter for x in sequence)
                or any(sequence[i - 1] >= sequence[i] for i in range(1, count))):
            return None
    return mode, count, parameter, sequence


def _encode(mode: int, parameter: int, values: Sequence[int]) -> bytes:
    if mode == 7:  # source-described 7-bit payloads with continuation flags
        result = bytearray()
        for value in values:
            shifts = [shift for shift in range(21, -1, -7) if value >> shift]
            if not shifts:
                shifts = [0]
            for index, shift in enumerate(shifts):
                payload = (value >> shift) & 0x7F
                result.append(payload | (0x80 if index + 1 < len(shifts) else 0))
        return bytes(result)
    if mode == 8:
        return _pack_ascii_bits(_simple9(values))
    bits = _Bits()
    if mode == 0:  # unary
        for value in values:
            bits.unary(value)
    elif mode == 1:  # minimal binary over [0, U)
        for value in values:
            _minimal_binary(bits, value, parameter)
    elif mode == 2:  # Elias C_gamma
        for value in values:
            _gamma(bits, value)
    elif mode == 3:  # Elias C_delta
        for value in values:
            _delta(bits, value)
    elif mode == 4:  # Golomb with explicit b, coding values directly
        for value in values:
            quotient, remainder = divmod(value, parameter)
            bits.unary(quotient)
            _minimal_binary(bits, remainder, parameter)
    elif mode == 5:  # Elias-Fano: bucket-count unary stream then low parts
        width = 0
        while len(values) * (1 << (width + 1)) <= parameter:
            width += 1
        bucket_size = 1 << width
        bucket_count = (parameter + bucket_size - 1) // bucket_size
        counts = [0] * bucket_count
        for value in values:
            counts[value // bucket_size] += 1
        for count in counts:
            bits.unary(count)
        for value in values:
            bits.number(value % bucket_size, width)
    elif mode == 6:  # binary interpolative code; lower middle is a stable source-allowed choice
        _interpolative(bits, values, 0, len(values), 0, parameter)
    elif mode == 9:  # bounded PForDelta block with explicit position/value exceptions
        width = parameter
        low_mask = (1 << width) - 1
        for value in values:
            bits.number(value & low_mask, width)
        exceptions = [(position, value) for position, value in enumerate(values)
                      if value >= (1 << width)]
        bits.number(len(exceptions), 6)
        position_width = (len(values) - 1).bit_length()
        for position, value in exceptions:
            bits.number(position, position_width)
            bits.number(value, 20)
    packed = _pack_ascii_bits(bits.data)
    if len(packed) > MAX_OUTPUT_BYTES:
        raise AssertionError("bounded profile exceeded its output limit")
    return packed


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _validate(values)
    if decoded is None:
        return -1, b""
    payload = _encode(decoded[0], decoded[2], decoded[3])
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
