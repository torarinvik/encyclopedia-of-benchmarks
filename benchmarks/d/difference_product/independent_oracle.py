"""Direct small-input oracle for ordered pairwise differences."""

MODULUS = 998244353
MAX_COUNT = 65536


def expected(values, length=None):
    if values is None:
        return -1
    if length is None:
        length = len(values)
    if length != len(values) or not values or values[0] < 0 or values[0] > MAX_COUNT:
        return -1
    count = values[0]
    if len(values) != count + 1 or any(not 0 <= x < MODULUS for x in values[1:]):
        return -1
    points = values[1:]
    if len(set(points)) != count:
        return 0
    # For an arithmetic progression, group the pair factors by their gap.
    # This provides a linear-time oracle for large structured cases.
    if count >= 2:
        difference = (points[1] - points[0]) % MODULUS
        if all((points[i] - points[i - 1]) % MODULUS == difference for i in range(2, count)):
            factorial = 1
            result = pow((-difference) % MODULUS, count * (count - 1) // 2, MODULUS)
            for gap in range(1, count):
                factorial = factorial * gap % MODULUS
                result = result * factorial % MODULUS
            return result
    result = 1
    for i in range(count):
        for j in range(i + 1, count):
            result = result * (values[i + 1] - values[j + 1]) % MODULUS
    return result
