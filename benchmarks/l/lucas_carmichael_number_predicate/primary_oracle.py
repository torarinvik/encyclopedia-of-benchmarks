"""Trial-factor reference for the bounded Lucas–Carmichael predicate."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VALUE = 1
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_TRIAL_DIVISOR = 1_000
MAX_FACTOR_CANDIDATES = 999
WORKSPACE_BYTES = 128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    value = values[0]
    return value if MIN_VALUE <= value <= MAX_VALUE else None


def _classify_by_factor_walk(value: int) -> int:
    """Remove one discovered prime power at a time from the residual."""
    remaining = value
    divisor = 2
    composite = False
    while divisor <= remaining // divisor:
        if remaining % divisor == 0:
            composite = True
            exponent = 0
            while remaining % divisor == 0:
                remaining //= divisor
                exponent += 1
            if exponent != 1 or (value + 1) % (divisor + 1) != 0:
                return 0
        divisor += 1
    if remaining > 1:
        if not composite or (value + 1) % (remaining + 1) != 0:
            return 0
    return int(composite)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return 1 for a Lucas–Carmichael number, 0 otherwise, -1 if invalid."""
    value = _decode(values, input_is_null, input_length)
    return -1 if value is None else _classify_by_factor_walk(value)
