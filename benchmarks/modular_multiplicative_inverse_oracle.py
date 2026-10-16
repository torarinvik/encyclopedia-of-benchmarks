"""Oracle for the bounded extended-Euclidean modular inverse benchmark."""

def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1
    a, modulus = values
    if not 2 <= modulus <= 1_000_000 or not 0 <= a < modulus:
        return -1
    old_r, r = a, modulus
    old_s, s = 1, 0
    while r:
        q = old_r // r
        old_r, r = r, old_r - q * r
        old_s, s = s, old_s - q * s
    return old_s % modulus if old_r == 1 else -1
