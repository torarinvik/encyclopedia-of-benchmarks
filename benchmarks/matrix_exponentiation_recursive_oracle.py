"""Runtime oracle for recursive 2x2 matrix exponentiation by squaring."""
import struct


def _multiply(a: tuple[int, ...], b: tuple[int, ...]) -> tuple[int, ...]:
    return tuple(sum(a[row * 2 + k] * b[k * 2 + col] for k in range(2))
                 for row in range(2) for col in range(2))


def _power(matrix: tuple[int, ...], exponent: int) -> tuple[int, ...]:
    if exponent == 0:
        return (1, 0, 0, 1)
    if exponent & 1:
        return _multiply(_power(matrix, exponent - 1), matrix)
    half = _power(matrix, exponent // 2)
    return _multiply(half, half)


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 5
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -2, b""
    exponent, *entries = values
    if not 0 <= exponent <= 30 or any(not -1 <= entry <= 1 for entry in entries):
        return -2, b""
    result = _power(tuple(entries), exponent)
    return 4, b"".join(struct.pack("<q", value) for value in result)
