"""Pohlig–Hellman discrete logarithm using prime-order BSGS subproblems."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

MIN_P = 3
MAX_P = 1_009
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
NO_LOG_RESULT = -2
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 3:
        return None
    p, base, target = values
    if not MIN_P <= p <= MAX_P or not 1 <= base < p or not 0 <= target < p:
        return None
    return p, base, target


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor = 3 if divisor == 2 else divisor + 2
    return True


def _factor(value: int) -> list[tuple[int, int]]:
    factors: list[tuple[int, int]] = []
    prime = 2
    remaining = value
    while prime * prime <= remaining:
        if remaining % prime == 0:
            exponent = 0
            while remaining % prime == 0:
                remaining //= prime
                exponent += 1
            factors.append((prime, exponent))
        prime = 3 if prime == 2 else prime + 2
    if remaining > 1:
        factors.append((remaining, 1))
    return factors


def _pow_mod(base: int, exponent: int, modulus: int) -> int:
    result = 1
    factor = base % modulus
    while exponent > 0:
        if exponent & 1:
            result = result * factor % modulus
        factor = factor * factor % modulus
        exponent >>= 1
    return result


def _order(base: int, prime_modulus: int, p_minus_one_factors: list[tuple[int, int]]) -> int:
    order = prime_modulus - 1
    for prime, _ in p_minus_one_factors:
        while order % prime == 0 and _pow_mod(base, order // prime, prime_modulus) == 1:
            order //= prime
    return order


def _prime_order_log(generator: int, target: int, order: int, modulus: int) -> int | None:
    if order == 1:
        return 0 if target == 1 else None
    step = isqrt(order)
    if step * step < order:
        step += 1
    baby_steps = {_pow_mod(generator, index, modulus): index for index in range(step)}
    giant_stride = _pow_mod(_pow_mod(generator, step, modulus), modulus - 2, modulus)
    probe = target
    for giant_index in range(step + 1):
        small_index = baby_steps.get(probe)
        if small_index is not None:
            candidate = giant_index * step + small_index
            if candidate < order:
                return candidate
        probe = probe * giant_stride % modulus
    return None


def _inverse(value: int, modulus: int) -> int:
    old_r, remainder = value, modulus
    old_s, coefficient = 1, 0
    while remainder:
        quotient = old_r // remainder
        old_r, remainder = remainder, old_r - quotient * remainder
        old_s, coefficient = coefficient, old_s - quotient * coefficient
    if old_r != 1:
        raise ArithmeticError("CRT component moduli must be coprime")
    return old_s % modulus


def _pohlig_hellman(base: int, target: int, modulus: int) -> int:
    if target == 0:
        return NO_LOG_RESULT
    modulus_factors = _factor(modulus - 1)
    order = _order(base, modulus, modulus_factors)
    order_factors: list[tuple[int, int]] = []
    remaining_order = order
    for prime, _ in modulus_factors:
        exponent = 0
        while remaining_order % prime == 0:
            remaining_order //= prime
            exponent += 1
        if exponent:
            order_factors.append((prime, exponent))

    if order == 1:
        return 0 if target == 1 else NO_LOG_RESULT

    solution = 0
    combined_modulus = 1
    for prime, exponent in order_factors:
        component_modulus = prime ** exponent
        partial_log = 0
        place = 1
        prime_generator = _pow_mod(base, order // prime, modulus)
        for _ in range(exponent):
            current_power = _pow_mod(base, partial_log, modulus)
            inverse_current = _pow_mod(current_power, modulus - 2, modulus)
            residual = target * inverse_current % modulus
            digit_target = _pow_mod(residual, order // (place * prime), modulus)
            digit = _prime_order_log(prime_generator, digit_target, prime, modulus)
            if digit is None:
                return NO_LOG_RESULT
            partial_log += digit * place
            place *= prime

        if combined_modulus == 1:
            solution = partial_log
            combined_modulus = component_modulus
        else:
            adjustment = ((partial_log - solution) % component_modulus
                          * _inverse(combined_modulus % component_modulus, component_modulus))
            adjustment %= component_modulus
            solution += combined_modulus * adjustment
            combined_modulus *= component_modulus

    solution %= order
    if _pow_mod(base, solution, modulus) != target:
        return NO_LOG_RESULT
    return solution


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    modulus, base, target = parsed
    if not _is_prime(modulus):
        return INVALID_RESULT
    return _pohlig_hellman(base, target, modulus)
