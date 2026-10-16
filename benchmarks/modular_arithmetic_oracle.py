"""Reference for the validated add, subtract, and multiply operations of ModRing."""

def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) != 4
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    operation, modulus, a, b = values
    if not 0 <= operation <= 2 or not 1 <= modulus <= 1_000_000:
        return -1
    if not (0 <= a < modulus and 0 <= b < modulus):
        return -1
    if operation == 0:
        return ((a % modulus) + (b % modulus)) % modulus
    if operation == 1:
        return ((a % modulus) - (b % modulus) + modulus) % modulus
    return ((a % modulus) * (b % modulus)) % modulus
