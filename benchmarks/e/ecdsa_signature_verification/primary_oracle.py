"""Primary ECDSA reference for the bounded toy prime-field domain."""
from __future__ import annotations

MAX_INPUT_LENGTH = 11
MAX_OUTPUT_BYTES = 1
MAX_WORKSPACE_BYTES = 512
DOMAIN = (17, 2, 2, 5, 1, 19)


def _mod(value: int, modulus: int) -> int:
    return value % modulus


def _inverse(value: int, modulus: int) -> int | None:
    old_r, r = modulus, _mod(value, modulus)
    old_t, t = 0, 1
    while r:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_t, t = t, old_t - quotient * t
    return _mod(old_t, modulus) if old_r == 1 else None


def _add(left: tuple[int, int] | None,
         right: tuple[int, int] | None) -> tuple[int, int] | None:
    if left is None:
        return right
    if right is None:
        return left
    x1, y1 = left
    x2, y2 = right
    if x1 == x2 and (y1 + y2) % 17 == 0:
        return None
    if left == right:
        denominator = (2 * y1) % 17
        numerator = (3 * x1 * x1 + 2) % 17
    else:
        denominator = (x2 - x1) % 17
        numerator = (y2 - y1) % 17
    inverse = _inverse(denominator, 17)
    if inverse is None:
        return None
    slope = numerator * inverse % 17
    x3 = (slope * slope - x1 - x2) % 17
    y3 = (slope * (x1 - x3) - y1) % 17
    return x3, y3


def _multiply(point: tuple[int, int] | None, scalar: int) -> tuple[int, int] | None:
    result = None
    addend = point
    while scalar:
        if scalar & 1:
            result = _add(result, addend)
        scalar >>= 1
        if scalar:
            addend = _add(addend, addend)
    return result


def expected_output(values, output_capacity: int | None = None,
                   output_is_null: bool = False) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    p, a, b, gx, gy, n, qx, qy, digest, r, s = values
    if (p, a, b, gx, gy, n) != DOMAIN:
        return -1, b""
    if not (0 <= qx < p and 0 <= qy < p and 0 <= digest <= 31
            and 1 <= r < n and 1 <= s < n):
        return -1, b""
    if (4 * a**3 + 27 * b**2) % p == 0:
        return -1, b""
    if (gy * gy - gx**3 - a * gx - b) % p:
        return -1, b""
    if (qy * qy - qx**3 - a * qx - b) % p:
        return -1, b""
    base = (gx, gy)
    public = (qx, qy)
    if _multiply(base, n) is not None or _multiply(public, n) is not None:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    w = _inverse(s, n)
    if w is None:
        return -1, b""
    u1 = digest * w % n
    u2 = r * w % n
    point = _add(_multiply(base, u1), _multiply(public, u2))
    valid = point is not None and point[0] % n == r
    return MAX_OUTPUT_BYTES, bytes((1 if valid else 0,))
