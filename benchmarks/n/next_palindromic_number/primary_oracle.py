"""Decimal-prefix mirroring and carry reference."""

MAX_INPUT = 9_999_999_999_999_999
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID = -1


def expected(values, input_is_null=False, input_length=None):
    if input_is_null:
        return INVALID
    if input_length is None and isinstance(values, (list, tuple)):
        input_length = len(values)
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or input_length != len(values)
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_INPUT):
        return INVALID

    number = values[0]
    digits = [ord(character) - ord("0") for character in str(number)]
    length = len(digits)
    for left in range(length // 2):
        digits[length - 1 - left] = digits[left]
    candidate = int("".join(str(digit) for digit in digits))
    if candidate > number:
        return candidate

    prefix_length = (length + 1) // 2
    position = prefix_length - 1
    while position >= 0 and digits[position] == 9:
        digits[position] = 0
        position -= 1
    if position < 0:
        return 10 ** length + 1

    digits[position] += 1
    for left in range(length // 2):
        digits[length - 1 - left] = digits[left]
    return int("".join(str(digit) for digit in digits))
