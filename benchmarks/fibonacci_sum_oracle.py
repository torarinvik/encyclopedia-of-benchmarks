"""Direct summation reference for the bounded Fibonacci range contract."""


def expected_result(start, end):
    if not 0 <= start <= end <= 90:
        return -1
    a, b, total = 0, 1, 0
    for index in range(end + 1):
        if index >= start:
            total += a
        a, b = b, a + b
    return total
