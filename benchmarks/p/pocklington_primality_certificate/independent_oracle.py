"""Direct-multiplication reference for bounded Pocklington certificates."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 65_535
MAX_FACTORS = 6
MAX_EXPONENT = 16
MAX_VALID_INPUT_LENGTH = 21
MAX_PARSEABLE_INPUT_LENGTH = 22


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[tuple[int, int, int]], int] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63) for item in values):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    count = values[1]
    if n < 3 or n > MAX_N or count < 1 or count > MAX_FACTORS:
        return None
    if len(values) != 3 + 3 * count:
        return None
    entries: list[tuple[int, int, int]] = []
    last = 1
    part = 1
    for i in range(count):
        prime = values[2 + i * 3]
        exponent = values[3 + i * 3]
        base = values[4 + i * 3]
        if prime <= last or prime < 2 or exponent < 1 or exponent > MAX_EXPONENT or base < 1 or base >= n:
            return None
        last = prime
        entries.append((prime, exponent, base))
        repeats = 0
        while repeats < exponent:
            if part > (n - 1) // prime:
                return None
            part *= prime
            repeats += 1
    rest = values[-1]
    if rest < 1 or rest > n - 1 or rest * part != n - 1:
        return None
    return n, entries, part


def _trial_is_prime(value: int) -> bool:
    if value < 2:
        return False
    candidate = 2
    while candidate * candidate <= value:
        if value % candidate == 0:
            return False
        candidate += 1
    return True


def _multiply_to_power(base: int, exponent: int, modulus: int) -> int:
    residue = 1
    step = 0
    reduced_base = base % modulus
    while step != exponent:
        residue = (residue * reduced_base) % modulus
        step += 1
    return residue


def _has_unit_gcd(value: int, modulus: int) -> bool:
    if value == 0:
        return False
    candidate = 2
    limit = min(value, modulus)
    while candidate <= limit:
        if value % candidate == 0 and modulus % candidate == 0:
            return False
        candidate += 1
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, entries, factored_part = decoded
    for prime, _, _ in entries:
        if not _trial_is_prime(prime):
            return -1
    if factored_part * factored_part <= n:
        return 0
    for prime, _, base in entries:
        if _multiply_to_power(base, n - 1, n) != 1:
            return 0
        remainder = _multiply_to_power(base, (n - 1) // prime, n)
        difference = (remainder + n - 1) % n
        if not _has_unit_gcd(difference, n):
            return 0
    return 1


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return type(result) is int and result == expected_result(values, input_is_null, input_length)
