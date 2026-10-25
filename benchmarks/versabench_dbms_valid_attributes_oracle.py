"""Oracle for the bounded tagged-list profile of VersaBench validAttributes."""
from __future__ import annotations

from collections.abc import Sequence

MAX_ATTRIBUTES = 51
MAX_INPUT_LENGTH = 1 + 2 * MAX_ATTRIBUTES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1


def _key_float_is_valid(bits_value: int) -> bool | None:
    if not 0 <= bits_value <= 0xffff_ffff:
        return None
    bits = bits_value
    exponent = (bits >> 23) & 0xff
    fraction = bits & 0x7f_ffff
    # C compares the decoded float to +/- FLT_MAX. NaNs pass both comparisons;
    # infinities fail, and every finite binary32 value is within the float range.
    return not (exponent == 0xff and fraction == 0)


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1
    count = values[0]
    if not 0 <= count <= MAX_ATTRIBUTES or len(values) != 1 + 2 * count:
        return -1
    for i in range(count):
        code, payload = values[1 + 2*i:3 + 2*i]
        # The pinned routine returns false immediately for an out-of-range code,
        # before looking at the union payload.
        if not 0 <= code <= 50:
            return 0
        if code < 8:
            valid = _key_float_is_valid(payload)
            if valid is None:
                return -1
            if not valid:
                return 0
        else:
            if payload not in (0, 1):
                return -1
            if payload == 0:  # source non-key pointer is NULL
                return 0
    return 1


oracle = expected_result
