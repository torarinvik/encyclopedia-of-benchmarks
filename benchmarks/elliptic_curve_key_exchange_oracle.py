"""Exact bounded oracle for affine ECDH over small prime fields."""
from __future__ import annotations

MAX_FIELD = 251
MAX_SCALAR = 1024
MAX_OUTPUT_BYTES = 48
MAX_INPUT_LENGTH = 7


def _prime(p: int) -> bool:
    return p >= 2 and all(p % d for d in range(2, int(p**0.5) + 1))


def _add(p: int, a: int, left: tuple[int, int] | None,
         right: tuple[int, int] | None) -> tuple[int, int] | None:
    if left is None: return right
    if right is None: return left
    x1, y1 = left; x2, y2 = right
    if x1 == x2 and (y1 + y2) % p == 0: return None
    if left == right:
        slope = ((3 * x1 * x1 + a) * pow(2 * y1, -1, p)) % p
    else:
        slope = ((y2 - y1) * pow((x2 - x1) % p, -1, p)) % p
    x3 = (slope * slope - x1 - x2) % p
    y3 = (slope * (x1 - x3) - y1) % p
    return x3, y3


def _mul(p: int, a: int, point: tuple[int, int] | None, scalar: int):
    result = None
    addend = point
    while scalar:
        if scalar & 1: result = _add(p, a, result, addend)
        scalar >>= 1
        if scalar: addend = _add(p, a, addend, addend)
    return result


def expected_output(values, output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != 7
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return -1, b""
    p, a, b, x, y, alice, bob = values
    if not 5 <= p <= MAX_FIELD or not _prime(p): return -1, b""
    if not (0 <= a < p and 0 <= b < p and 0 <= x < p and 0 <= y < p): return -1, b""
    if (4 * a**3 + 27 * b**2) % p == 0: return -1, b""
    if (y * y - (x**3 + a * x + b)) % p: return -1, b""
    if not (1 <= alice <= MAX_SCALAR and 1 <= bob <= MAX_SCALAR): return -1, b""
    if output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES: return -2, b""
    base = (x, y)
    alice_public = _mul(p, a, base, alice)
    bob_public = _mul(p, a, base, bob)
    shared = _mul(p, a, alice_public, bob)
    if shared != _mul(p, a, bob_public, alice): raise AssertionError("ECDH symmetry")
    out = bytearray()
    for point in (alice_public, bob_public, shared):
        out.extend(((-1, -1) if point is None else point)[0].to_bytes(8, "little", signed=True))
        out.extend(((-1, -1) if point is None else point)[1].to_bytes(8, "little", signed=True))
    return MAX_OUTPUT_BYTES, bytes(out)
