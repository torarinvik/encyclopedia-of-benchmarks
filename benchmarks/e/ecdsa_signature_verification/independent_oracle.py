"""Independent exhaustive ECDSA oracle for the fixed order-19 curve.

It recovers the public point's discrete logarithm and scans every possible
nonce, checking the signing relation directly. It does not compute the
verification inverse or the `u1*G + u2*Q` point used by the primary method.
"""
from __future__ import annotations

MAX_INPUT_LENGTH = 11
MAX_OUTPUT_BYTES = 1
MAX_WORKSPACE_BYTES = 512
DOMAIN = (17, 2, 2, 5, 1, 19)


def _inverse_by_scan(value: int, modulus: int) -> int | None:
    value %= modulus
    for candidate in range(1, modulus):
        if (value * candidate) % modulus == 1:
            return candidate
    return None


def _step(point: tuple[int, int] | None,
          addend: tuple[int, int] | None) -> tuple[int, int] | None:
    if point is None:
        return addend
    if addend is None:
        return point
    x1, y1 = point
    x2, y2 = addend
    if x1 == x2 and (y1 + y2) % 17 == 0:
        return None
    if point == addend:
        denominator, numerator = (2 * y1) % 17, (3 * x1 * x1 + 2) % 17
    else:
        denominator, numerator = (x2 - x1) % 17, (y2 - y1) % 17
    inverse = _inverse_by_scan(denominator, 17)
    if inverse is None:
        return None
    slope = numerator * inverse % 17
    x3 = (slope * slope - x1 - x2) % 17
    return x3, (slope * (x1 - x3) - y1) % 17


def _repeat_add(point: tuple[int, int], count: int) -> tuple[int, int] | None:
    result = None
    for _ in range(count):
        result = _step(result, point)
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
    if _repeat_add(base, n) is not None or _repeat_add(public, n) is not None:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return -2, b""

    private_scalar = None
    point = None
    for candidate in range(1, n):
        point = _step(point, base)
        if point == public:
            private_scalar = candidate
            break
    if private_scalar is None:
        return MAX_OUTPUT_BYTES, b"\x00"

    point = None
    valid = False
    right_hand_side = (digest + r * private_scalar) % n
    for nonce in range(1, n):
        point = _step(point, base)
        if point is not None and point[0] % n == r:
            valid = (s * nonce) % n == right_hand_side
            if valid:
                break
    return MAX_OUTPUT_BYTES, bytes((1 if valid else 0,))
