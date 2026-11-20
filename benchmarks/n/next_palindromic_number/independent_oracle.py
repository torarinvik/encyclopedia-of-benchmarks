"""Independent prefix-search reference for the next decimal palindrome."""

MAX_INPUT = 9_999_999_999_999_999
INVALID = -1
MAX_DIGITS = 17


def _palindrome_from_prefix(prefix, digits):
    left = str(prefix)
    mirrored = left[:-1][::-1] if digits % 2 else left[::-1]
    return int(left + mirrored)


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
    first_digits = len(str(number))
    for digits in range(first_digits, MAX_DIGITS + 1):
        prefix_digits = (digits + 1) // 2
        low = 1 if prefix_digits == 1 else 10 ** (prefix_digits - 1)
        high = 10 ** prefix_digits - 1
        left, right = low, high
        while left < right:
            middle = (left + right) // 2
            if _palindrome_from_prefix(middle, digits) > number:
                right = middle
            else:
                left = middle + 1
        candidate = _palindrome_from_prefix(left, digits)
        if candidate > number:
            return candidate
    return INVALID
