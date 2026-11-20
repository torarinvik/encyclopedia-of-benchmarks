"""Cycle-type partition enumeration for the bounded permutation count."""

from math import factorial

MAX_N = 20
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: list[int] | tuple[int, ...] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n, cap = values
    if not 1 <= n <= MAX_N or not 1 <= cap <= n:
        return None
    return n, cap


def _count_by_cycle_types(n: int, cap: int) -> int:
    numerator = factorial(n)
    total = 0

    def visit(cycle_length: int, remaining: int, denominator: int) -> None:
        nonlocal total
        if remaining == 0:
            total += numerator // denominator
            return
        if cycle_length > cap:
            return
        max_multiplicity = remaining // cycle_length
        multiplicity_factor = 1
        for multiplicity in range(max_multiplicity + 1):
            visit(cycle_length + 1,
                  remaining - multiplicity * cycle_length,
                  denominator * multiplicity_factor)
            multiplicity_factor *= cycle_length * (multiplicity + 1)

    visit(1, n, 1)
    return total


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, cap = parsed
    return _count_by_cycle_types(n, cap)


random_permutation_cycle_cap_count = expected_result
