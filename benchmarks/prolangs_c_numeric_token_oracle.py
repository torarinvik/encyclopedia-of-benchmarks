"""Independent binary32 model for Prolangs-C's bounded numeric token profile."""
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 24
MAX_PARSEABLE_INPUT_LENGTH = 25
MAX_OUTPUT_BYTES = 12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value):
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _encode(values):
    if not isinstance(values, (list, tuple)) or not (1 <= len(values) <= MAX_INPUT_LENGTH):
        return None
    if any(type(v) is not int or v < 32 or v > 127 for v in values):
        return None
    try:
        text = bytes(values).decode("ascii")
    except (ValueError, UnicodeDecodeError):
        return None
    if not text or any(c not in "0123456789.eE+-" for c in text):
        return None

    # A Number() invocation begins on a digit or dot; signs only occur in exponent.
    i = 0
    integer = 0
    if text[i].isdigit():
        start = i
        while i < len(text) and text[i].isdigit():
            i += 1
        integer = int(text[start:i])
        if integer > 2147483647:
            return None
        if i == len(text):
            return struct.pack("<iii", 256, integer, 0)
    fraction = _f32(0.0)
    real = False
    if i < len(text) and text[i] == ".":
        real = True
        i += 1
        zeros = 0
        while i < len(text) and text[i] == "0":
            zeros += 1
            if zeros > 6:
                return None
            i += 1
        start = i
        while i < len(text) and text[i].isdigit():
            i += 1
        frac_digits = text[start:i]
        if zeros + len(frac_digits) > 6:
            return None
        if frac_digits:
            decimal = int(frac_digits)
            fraction = _f32(float(decimal))
            while fraction >= 1.0:
                fraction = _f32(fraction / 10.0)
            while zeros:
                fraction = _f32(fraction / 10.0)
                zeros -= 1
    value = _f32(fraction + _f32(float(integer)))
    if i < len(text) and text[i] in "eE":
        real = True
        i += 1
        sign = 1
        if i < len(text) and text[i] in "+-":
            if text[i] == "-":
                sign = -1
            i += 1
        start = i
        while i < len(text) and text[i].isdigit():
            i += 1
        if start == i:
            return None
        exponent = sign * int(text[start:i])
        if exponent < -6 or exponent > 6:
            return None
        while exponent > 0:
            value = _f32(value * 10.0)
            exponent -= 1
        while exponent < 0:
            value = _f32(value / 10.0)
            exponent += 1
    if i != len(text) or not real:
        return None
    bits = struct.unpack("<i", struct.pack("<f", value))[0]
    return struct.pack("<iii", 2001, integer, bits)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))):
        return INVALID_RESULT, b""
    encoded = _encode(values)
    if encoded is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or type(output_capacity) is not int
            or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, encoded


def evaluate(values):
    """Convenience fixture helper returning encoded bytes or None if invalid."""
    return _encode(values)

