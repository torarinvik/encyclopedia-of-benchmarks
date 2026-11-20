"""Independent built-in-codec reference plus insertion-state decoder."""

from __future__ import annotations

from collections.abc import Sequence

MAX_CODEPOINTS = 32
MAX_VALID_INPUT_WORDS = 33
MAX_PARSEABLE_INPUT_WORDS = 34
MAX_VALID_INPUT_LENGTH = MAX_VALID_INPUT_WORDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_PARSEABLE_INPUT_WORDS
MAX_OUTPUT_BYTES = 320
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_BASE = 36
_TMIN = 1
_TMAX = 26
_SKEW = 38
_DAMP = 700
_INITIAL_N = 128
_INITIAL_BIAS = 72


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_CODEPOINTS or len(values) != count + 1:
        return None
    result = list(values[1:])
    if any(cp < 0 or cp > 0x10FFFF or 0xD800 <= cp <= 0xDFFF for cp in result):
        return None
    return result


def _adapt(delta: int, point_count: int, first_time: bool) -> int:
    delta //= _DAMP if first_time else 2
    delta += delta // point_count
    divisions = 0
    while delta > ((_BASE - _TMIN) * _TMAX) // 2:
        delta //= _BASE - _TMIN
        divisions += 1
    return _BASE * divisions + ((_BASE - _TMIN + 1) * delta) // (delta + _SKEW)


def _digit_value(byte: int) -> int:
    if 0x41 <= byte <= 0x5A:
        return byte - 0x41
    if 0x61 <= byte <= 0x7A:
        return byte - 0x61
    if 0x30 <= byte <= 0x39:
        return byte - 0x30 + 26
    return -1


def decode_payload(payload: bytes) -> tuple[int, ...] | None:
    """Decode Punycode by inserting code points into the growing prefix."""
    if any(byte >= 0x80 for byte in payload):
        return None
    delimiter = payload.rfind(b"-")
    if delimiter >= 0:
        output = list(payload[:delimiter])
        position = delimiter + 1
    else:
        output = []
        position = 0
    if any(cp >= 0x80 for cp in output):
        return None

    n = _INITIAL_N
    insertion = 0
    bias = _INITIAL_BIAS
    while position < len(payload):
        old_insertion = insertion
        weight = 1
        k = _BASE
        while True:
            if position >= len(payload):
                return None
            digit = _digit_value(payload[position])
            position += 1
            if digit < 0 or digit > ((1 << 63) - 1 - insertion) // weight:
                return None
            insertion += digit * weight
            if k <= bias:
                threshold = _TMIN
            elif k >= bias + _TMAX:
                threshold = _TMAX
            else:
                threshold = k - bias
            if digit < threshold:
                break
            factor = _BASE - threshold
            if weight > ((1 << 63) - 1) // factor:
                return None
            weight *= factor
            k += _BASE

        point_count = len(output) + 1
        bias = _adapt(insertion - old_insertion, point_count, old_insertion == 0)
        n += insertion // point_count
        insertion %= point_count
        if n > 0x10FFFF or 0xD800 <= n <= 0xDFFF:
            return None
        output.insert(insertion, n)
        insertion += 1
    return tuple(output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_WORDS)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    codepoints = _parse(values, input_is_null, input_length)
    if codepoints is None:
        return INVALID_RESULT, b""
    text = "".join(chr(cp) for cp in codepoints)
    payload = text.encode("punycode")
    if (len(payload) > MAX_OUTPUT_BYTES or decode_payload(payload) != tuple(codepoints)):
        return INVALID_RESULT, b""
    if output_is_null and payload or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
