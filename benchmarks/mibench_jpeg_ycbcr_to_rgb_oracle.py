"""Independent bounded oracle for the IJG 8-bit YCbCr-to-RGB table kernel."""
from __future__ import annotations

from collections.abc import Sequence

MAX_PIXELS = 16
MAX_INPUT_LENGTH = 1 + 3 * MAX_PIXELS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 3 * MAX_PIXELS

def _fix(value: float) -> int:
    # IJG FIX(x): cast x*2^16 + .5 to signed integer (positive constants).
    return int(value * 65536 + 0.5)

def _arshift(value: int, bits: int = 16) -> int:
    # IJG RIGHT_SHIFT is arithmetic for this signed 32-bit profile.
    return value // (1 << bits)

def _clamp(value: int) -> int:
    return min(255, max(0, value))

def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    count = values[0]
    if not 1 <= count <= MAX_PIXELS or len(values) != 1 + 3 * count:
        return -1, b""
    if any(not 0 <= v <= 255 for v in values[1:]):
        return -1, b""

    fix_cr_r = _fix(1.40200)
    fix_cb_b = _fix(1.77200)
    fix_cr_g = _fix(0.71414)
    fix_cb_g = _fix(0.34414)
    out = bytearray()
    for pos in range(1, len(values), 3):
        y, cb, cr = values[pos:pos + 3]
        cb -= 128
        cr -= 128
        rtab = _arshift(fix_cr_r * cr + 32768)
        btab = _arshift(fix_cb_b * cb + 32768)
        # Source leaves both green terms scaled, adds ONE_HALF to the Cb term,
        # then applies one arithmetic right shift after summation.
        gtab = _arshift((-fix_cb_g * cb + 32768) + (-fix_cr_g * cr))
        out.extend((_clamp(y + rtab), _clamp(y + gtab), _clamp(y + btab)))

    result = bytes(out)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(result):
        return -2, b""
    return len(result), result

oracle = expected_output
