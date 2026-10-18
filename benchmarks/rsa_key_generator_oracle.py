"""Oracle for the pinned Python RSA key generator with supplied randrange draws."""

from __future__ import annotations

from collections.abc import Callable, Sequence

INVALID_RESULT = -1
MIN_KEY_SIZE = 2
MAX_KEY_SIZE = 20
MAX_DRAWS = 1024
MAX_VALID_INPUT_LENGTH = 2 + MAX_DRAWS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1

FNV_OFFSET_BASIS = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = 0xFFFFFFFFFFFFFFFF
MASK63 = 0x7FFFFFFFFFFFFFFF
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


class _DrawStreamError(Exception):
    """A supplied randrange result is absent or outside the requested range."""


def _gcd_by_iterative(x: int, y: int) -> int:
    while y:
        x, y = y, x % y
    return abs(x)


def _find_mod_inverse(a: int, modulus: int) -> int:
    """Match the source helper's extended Euclidean update and final modulo."""
    if _gcd_by_iterative(a, modulus) != 1:
        raise _DrawStreamError
    u1, u2, u3 = 1, 0, a
    v1, v2, v3 = 0, 1, modulus
    while v3 != 0:
        quotient = u3 // v3
        v1, v2, v3, u1, u2, u3 = (
            u1 - quotient * v1,
            u2 - quotient * v2,
            u3 - quotient * v3,
            v1,
            v2,
            v3,
        )
    return u1 % modulus


def _is_low_prime(num: int) -> bool:
    """Model membership in the source's complete prime list through 997."""
    if num > 997:
        return False
    if num < 2:
        return False
    divisor = 2
    while divisor * divisor <= num:
        if num % divisor == 0:
            return False
        divisor += 1
    return True


def _is_prime_low_num(num: int, draw: Callable[[int, int], int]) -> bool:
    if num < 2:
        return False
    if _is_low_prime(num):
        return True
    # Testing every integer through 997 is equivalent to checking the source's
    # listed low primes: composite divisors add no new rejection cases.
    for divisor in range(2, 998):
        if num % divisor == 0:
            return False
    return _rabin_miller(num, draw)


def _rabin_miller(num: int, draw: Callable[[int, int], int]) -> bool:
    s = num - 1
    t = 0
    while s % 2 == 0:
        s //= 2
        t += 1

    # Preserve the pinned implementation's five rounds and control flow.
    for _ in range(5):
        base = draw(2, num - 1)
        value = pow(base, s, num)
        if value != 1:
            i = 0
            while value != num - 1:
                if i == t - 1:
                    return False
                i += 1
                value = (value * value) % num
    return True


def _fingerprint(public_key: tuple[int, int], private_key: tuple[int, int]) -> int:
    values = (public_key[0], public_key[1], private_key[0], private_key[1])
    fingerprint = FNV_OFFSET_BASIS
    for value in values:
        for byte in value.to_bytes(8, byteorder="little", signed=True):
            fingerprint ^= byte
            fingerprint = (fingerprint * FNV_PRIME) & MASK64
    return fingerprint & MASK63


def expected_result(input_values: Sequence[int] | None) -> int:
    """Return a fingerprint of ((n, e), (n, d)), or -1 for invalid input.

    Input is [key_size, draw_count, randrange_results...]. Each consumed result
    is checked against the exact half-open range requested by the source.
    """
    if input_values is None or not isinstance(input_values, Sequence):
        return INVALID_RESULT
    values = list(input_values)
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    if len(values) < 2:
        return INVALID_RESULT

    key_size, draw_count = values[:2]
    if not MIN_KEY_SIZE <= key_size <= MAX_KEY_SIZE:
        return INVALID_RESULT
    if not 0 <= draw_count <= MAX_DRAWS or len(values) != 2 + draw_count:
        return INVALID_RESULT

    draws = values[2:]
    draw_limit = 1 << key_size
    if any(not 2 <= value < draw_limit for value in draws):
        return INVALID_RESULT

    cursor = 0

    def draw(low: int, high: int) -> int:
        nonlocal cursor
        if cursor >= len(draws):
            raise _DrawStreamError
        value = draws[cursor]
        cursor += 1
        if not low <= value < high:
            raise _DrawStreamError
        return value

    def generate_large_prime() -> int:
        low = 1 << (key_size - 1)
        high = 1 << key_size
        while True:
            candidate = draw(low, high)
            if _is_prime_low_num(candidate, draw):
                return candidate

    try:
        p = generate_large_prime()
        q = generate_large_prime()
        n = p * q
        phi = (p - 1) * (q - 1)

        low = 1 << (key_size - 1)
        high = 1 << key_size
        while True:
            e = draw(low, high)
            if _gcd_by_iterative(e, phi) == 1:
                break

        d = _find_mod_inverse(e, phi)
        return _fingerprint((n, e), (n, d))
    except _DrawStreamError:
        return INVALID_RESULT
