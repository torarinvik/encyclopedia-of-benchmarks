"""Reference behavior for a portable bounded Chudnovsky pi benchmark."""

from __future__ import annotations

from decimal import Decimal, localcontext

MAX_PRECISION = 12
MAX_OUTPUT_BYTES = MAX_PRECISION


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not -(2**63) <= values[0] < 2**63
            or not 1 <= values[0] <= MAX_PRECISION):
        return -1, b""

    with localcontext() as context:
        context.prec = values[0]
        constant_term = 426880 * Decimal(10005).sqrt()
        result = str(constant_term / Decimal(13591409))[:-1].encode("ascii")
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(result) > capacity:
            return -2, b""
    return len(result), result
