"""Oracle for the bounded Legendre-symbol slice of the pinned Rust module."""
MAX_INPUT_LENGTH = 2
PRIMES = {3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53}

def expected_result(values: list[int]) -> int:
    if len(values) != 2:
        return -1
    a, p = values
    if p not in PRIMES or a < 0 or a >= p:
        return -1
    if a == 0:
        return 0
    return 1 if pow(a, (p - 1) // 2, p) == 1 else -1
