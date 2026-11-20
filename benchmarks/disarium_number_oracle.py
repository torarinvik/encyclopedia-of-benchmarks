"""Left-to-right digit model for the bounded Disarium predicate."""


def expected_result(value):
    if not 1 <= value <= 99_999_999:
        return -1
    digit_sum = sum(int(digit) ** position
                    for position, digit in enumerate(str(value), 1))
    return int(digit_sum == value)
