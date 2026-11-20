"""Digit-sum cube model for the bounded Dudeney predicate."""


def expected_result(value):
    if not 1 <= value <= 2_147_483_647:
        return -1
    digit_sum = sum(int(digit) for digit in str(value))
    return int(digit_sum ** 3 == value)
