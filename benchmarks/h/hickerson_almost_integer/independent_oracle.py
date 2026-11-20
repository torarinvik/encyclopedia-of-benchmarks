"""Direct high-precision factorial/power reference for Hickerson's formula."""

from __future__ import annotations

import math
from collections.abc import Sequence
from decimal import Decimal, localcontext

INVALID_RESULT = -1e300
MIN_N = 1
MAX_N = 17


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not MIN_N <= values[0] <= MAX_N):
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != 1):
        return INVALID_RESULT
    n = values[0]
    with localcontext() as context:
        context.prec = 100
        ln_two = Decimal(2).ln()
        value = Decimal(math.factorial(n)) / (Decimal(2) * (ln_two ** (n + 1)))
        return float(value)


expected_output = expected_result
