"""Independent bitwise oracle for the bounded Ghostscript ROP3 profile."""

MAX_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
INVALID_RESULT = -1
PIXEL_MAX = 0xFFFFFFFF


def expected_result(values):
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(v) is not int for v in values):
        return INVALID_RESULT
    if len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    d, s, t, code = values
    if any(v < 0 or v > PIXEL_MAX for v in (d, s, t)) or not 0 <= code <= 255:
        return INVALID_RESULT
    result = 0
    for bit in range(32):
        index = (((t >> bit) & 1) << 2) | (((s >> bit) & 1) << 1) | ((d >> bit) & 1)
        if (code >> index) & 1:
            result |= 1 << bit
    return result
