"""Runtime oracle for the bounded perfect-number predicate."""

MAX_INPUT_LENGTH = 1
MAX_VALUE = 1_000_000_000


def expected_result(values: list[int]) -> int:
    if (len(values) != 1 or type(values[0]) is not int
            or not 0 <= values[0] <= MAX_VALUE):
        return -1
    number = values[0]
    if number <= 1:
        return 0
    divisor_sum = 1
    divisor = 2
    while divisor <= number // divisor:
        if number % divisor == 0:
            divisor_sum += divisor
            paired = number // divisor
            if paired != divisor:
                divisor_sum += paired
        divisor += 1
    return int(divisor_sum == number)
