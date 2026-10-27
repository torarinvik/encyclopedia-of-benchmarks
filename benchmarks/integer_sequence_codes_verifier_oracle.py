"""Independent string-form verifier for the bounded integer sequence code modes."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 512


def _fixed(value: int, width: int) -> str:
    return format(value, f"0{width}b") if width else ""


def _short_code(value: int, universe: int) -> str:
    if universe == 1:
        return ""
    k = universe.bit_length() - 1
    cutoff = (1 << (k + 1)) - universe
    return _fixed(value, k) if value < cutoff else _fixed(value + cutoff, k + 1)


def _c_gamma(value: int) -> str:
    shifted = value + 1
    k = shifted.bit_length() - 1
    return "1" * k + "0" + _fixed(shifted - (1 << k), k)


def _c_delta(value: int) -> str:
    shifted = value + 1
    k = shifted.bit_length() - 1
    return _c_gamma(k) + _fixed(shifted - (1 << k), k)


def _interp(values: Sequence[int], left: int, right: int, low: int, high: int) -> str:
    if left == right:
        return ""
    mid = (left + right - 1) // 2
    lower = low + mid - left
    upper = high - (right - mid - 1)
    value = values[mid]
    return (_short_code(value - lower, upper - lower)
            + _interp(values, left, mid, low, value)
            + _interp(values, mid + 1, right, value + 1, high))


def _byte_aligned(values: Sequence[int]) -> bytes:
    result = bytearray()
    for value in values:
        digits = []
        current = value
        while current >= 128:
            digits.append(current % 128)
            current //= 128
        digits.append(current)
        digits.reverse()
        for index, digit in enumerate(digits):
            result.append(digit | (0x80 if index + 1 < len(digits) else 0))
    return bytes(result)


def _simple9(values: Sequence[int]) -> str:
    formats = ((28, 1), (14, 2), (9, 3), (7, 4), (5, 5),
               (4, 7), (3, 9), (2, 14), (1, 28))
    words = []
    offset = 0
    while offset < len(values):
        for selector, (slots, width) in enumerate(formats):
            chunk = values[offset:offset + slots]
            if all(value < (1 << width) for value in chunk):
                payload = "".join(_fixed(value, width) for value in chunk)
                payload += "0" * ((slots - len(chunk)) * width + 28 - slots * width)
                words.append(_fixed(selector, 4) + payload)
                offset += len(chunk)
                break
    return "".join(words)


def _bits(values: Sequence[int]) -> str | bytes:
    mode, count, parameter = values[:3]
    seq = values[3:]
    if mode == 0:
        return "".join("1" * value + "0" for value in seq)
    if mode == 1:
        return "".join(_short_code(value, parameter) for value in seq)
    if mode == 2:
        return "".join(_c_gamma(value) for value in seq)
    if mode == 3:
        return "".join(_c_delta(value) for value in seq)
    if mode == 4:
        words = []
        for value in seq:
            quotient, remainder = divmod(value, parameter)
            words.append("1" * quotient + "0" + _short_code(remainder, parameter))
        return "".join(words)
    if mode == 7:
        return _byte_aligned(seq)
    if mode == 8:
        return _simple9(seq)
    if mode == 9:
        width = parameter
        mask = (1 << width) - 1
        result = "".join(_fixed(value & mask, width) for value in seq)
        exceptions = [(index, value) for index, value in enumerate(seq) if value >= (1 << width)]
        result += _fixed(len(exceptions), 6)
        position_width = (count - 1).bit_length()
        for position, value in exceptions:
            result += _fixed(position, position_width) + _fixed(value, 20)
        return result
    if mode == 5:
        width = (parameter // count).bit_length() - 1
        bucket_size = 1 << width
        number_of_buckets = (parameter + bucket_size - 1) // bucket_size
        bucket_counts = [sum(x // bucket_size == bucket for x in seq)
                         for bucket in range(number_of_buckets)]
        high = "".join("1" * occupancy + "0" for occupancy in bucket_counts)
        low = "".join(_fixed(x % bucket_size, width) for x in seq)
        return high + low
    return _interp(seq, 0, count, 0, parameter)


def _valid(values: Sequence[int] | None) -> bool:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return False
    mode, n, parameter = values[:3]
    seq = values[3:]
    if mode not in range(10) or not 1 <= n <= 32 or len(seq) != n:
        return False
    if mode == 0:
        return parameter == 0 and all(0 <= x <= 31 for x in seq)
    if mode == 1:
        return 2 <= parameter <= 1_000_000 and all(0 <= x < parameter for x in seq)
    if mode in (2, 3):
        return parameter == 0 and all(0 <= x <= 1_000_000 for x in seq)
    if mode == 4:
        return 1 <= parameter <= 128 and all(0 <= x <= 127 for x in seq)
    if mode == 7:
        return parameter == 0 and all(0 <= x <= 1_000_000 for x in seq)
    if mode == 8:
        return parameter == 0 and all(0 <= x < (1 << 28) for x in seq)
    if mode == 9:
        return 1 <= parameter <= 20 and all(0 <= x <= 1_000_000 for x in seq)
    return (2 <= parameter <= 4096 and n <= parameter
            and all(0 <= x < parameter for x in seq)
            and all(seq[i - 1] < seq[i] for i in range(1, n)))


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
    if input_is_null or values is None or not _valid(values):
        return -1, b""
    encoded = _bits(values)
    if isinstance(encoded, bytes):
        raw = encoded
    else:
        packed = bytearray((len(encoded) + 7) // 8)
        for index, bit in enumerate(encoded):
            if bit == "1":
                packed[index // 8] |= 1 << (7 - index % 8)
        raw = bytes(packed)
    if len(raw) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return len(raw), raw
