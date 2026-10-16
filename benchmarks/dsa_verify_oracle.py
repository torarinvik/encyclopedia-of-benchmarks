"""Bounded deterministic verifier for the pinned Go DSA Verify routine."""
from collections.abc import Sequence

MAX_PRIME = 251
MAX_MESSAGE_BYTES = 8
MAX_INPUT_LENGTH = 7 + MAX_MESSAGE_BYTES
INVALID_RESULT = -1


def _is_prime(value: int) -> bool:
    return value >= 2 and all(value % divisor for divisor in range(2, int(value**0.5) + 1))


def expected_result(values: Sequence[int]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 7
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    p, q, g, y, r, s, message_length = values[:7]
    if (len(values) != 7 + message_length or message_length < 0
            or message_length > MAX_MESSAGE_BYTES):
        return INVALID_RESULT
    if p < 5 or p > MAX_PRIME or not _is_prime(p):
        return INVALID_RESULT
    if q < 2 or q >= p or (p - 1) % q != 0 or not _is_prime(q):
        return INVALID_RESULT
    if not 2 <= g < p or pow(g, q, p) != 1:
        return INVALID_RESULT
    if not 1 <= y < p or pow(y, q, p) != 1:
        return INVALID_RESULT
    if not 1 <= r < q or not 1 <= s < q:
        return INVALID_RESULT
    message = values[7:]
    if any(byte < 0 or byte > 255 for byte in message):
        return INVALID_RESULT
    h = 0
    for byte in message:
        h = (h << 8) | byte
    w = pow(s, q - 2, q)
    u1 = (h * w) % q
    u2 = (r * w) % q
    v = (pow(g, u1, p) * pow(y, u2, p) % p) % q
    return int(v == r)
