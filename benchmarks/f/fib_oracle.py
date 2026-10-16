"""Independent fast-doubling oracle for the shifted Fibonacci benchmark."""

def pair(n: int) -> tuple[int, int]:
    if n == 0:
        return 0, 1
    a, b = pair(n // 2)
    even = a * (2 * b - a)
    odd = a * a + b * b
    return (odd, even + odd) if n & 1 else (even, odd)

def expected_result(n: int) -> int:
    return pair(n + 2)[0] if 0 <= n <= 90 else -1
