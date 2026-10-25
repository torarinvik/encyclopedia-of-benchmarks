"""Oracle for the bounded IEEE-binary32 validIndexKey predicate."""
from __future__ import annotations

from collections.abc import Sequence

INPUT_LENGTH = 8
MAX_PARSEABLE_INPUT_LENGTH = 9
MAX_BINARY32_BITS = 0xffff_ffff


def _binary32_ge(a: int, b: int) -> bool:
    exp_a, frac_a = (a >> 23) & 0xff, a & 0x7f_ffff
    exp_b, frac_b = (b >> 23) & 0xff, b & 0x7f_ffff
    if (exp_a == 0xff and frac_a != 0) or (exp_b == 0xff and frac_b != 0):
        return False  # ordered comparison with NaN is false
    mag_a, mag_b = a & 0x7fff_ffff, b & 0x7fff_ffff
    if mag_a == 0 and mag_b == 0:
        return True  # +0 >= -0 and -0 >= +0
    neg_a, neg_b = bool(a >> 31), bool(b >> 31)
    if neg_a != neg_b:
        return not neg_a
    return mag_a <= mag_b if neg_a else mag_a >= mag_b


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
            or len(values) != INPUT_LENGTH):
        return -1
    if any(not 0 <= v <= MAX_BINARY32_BITS for v in values):
        return -1
    for d in range(4):
        if _binary32_ge(values[d], values[4+d]):
            return 0
    return 1


oracle = expected_result
