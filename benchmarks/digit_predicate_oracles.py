"""String-digit references for two bounded scalar benchmarks."""


def armstrong_digit_cubes(value):
    if not -(2**31) <= value < 2**31:
        return -1
    magnitude = abs(value)
    return int(sum(int(digit) ** 3 for digit in str(magnitude)) == magnitude)


def additive_persistence(value):
    if value < 0 or value > 2**63 - 1:
        return -1
    steps = 0
    while value >= 10:
        value = sum(int(digit) for digit in str(value))
        steps += 1
    return steps
