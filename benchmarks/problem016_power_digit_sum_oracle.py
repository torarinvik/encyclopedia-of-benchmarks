"""Independent oracle for the bounded Problem 016 power-digit-sum contract."""

INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    """Return the decimal digit sum, preserving the source's exponent-zero edge."""
    if not isinstance(values, list) or len(values) != 2:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT

    base, exponent = values
    if not 0 <= base <= 9 or not 0 <= exponent <= 1000:
        return INVALID_RESULT
    if exponent == 0:
        return base
    return sum(int(digit) for digit in str(base ** exponent))
