"""Modular fast-doubling model for the binary64 matrix benchmark."""
import math


def expected_result(index, modulus):
    if (not math.isfinite(index) or not math.isfinite(modulus)
            or not 1 <= index <= 9_007_199_254_740_991
            or not 1 <= modulus <= 4_294_967_295
            or index != int(index) or modulus != int(modulus)):
        return -1.0
    mod = int(modulus)

    def pair(n):
        if n == 0:
            return 0, 1 % mod
        a, b = pair(n // 2)
        even = (a * (2*b-a)) % mod
        odd = (a*a + b*b) % mod
        return (odd, (even + odd) % mod) if n % 2 else (even, odd)

    return float(pair(int(index))[0])
