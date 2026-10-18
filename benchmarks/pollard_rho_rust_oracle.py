"""Oracle for the bounded Rust Brent Pollard's rho source variant."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
U32_MAX = (1 << 32) - 1
MAX_PARSEABLE_LENGTH = 4
INVALID_RESULT = -1
NO_FACTOR_RESULT = 0
LCG_MASK = U32_MAX
LCG_MULTIPLIER = 1103515245
LCG_INCREMENT = 12345
ITERATIONS_BEFORE_CHECK = 32
ITERATIONS_CUTOFF = 1 << 18


def _gcd(left: int, right: int) -> int:
    while left:
        left, right = right % left, left
    return right


def _mod_power(base: int, power: int, modulus: int) -> int:
    base %= modulus
    if base == 0:
        return 0
    result = 1
    while power > 0:
        if power & 1:
            result = result * base % modulus
        base = base * base % modulus
        power >>= 1
    return result


def _source_probable_prime(number: int) -> bool:
    """Match the pinned Miller-Rabin helper and its bases on this domain."""
    if number <= 4:
        return number in (2, 3)
    bases = [2, 3, 5, 7]
    if number > 3_215_031_000:
        bases.extend((11, 13, 17, 19, 23, 29, 31, 37))
    if number in bases:
        return True

    two_power = 0
    odd_power = number - 1
    while odd_power % 2 == 0:
        odd_power //= 2
        two_power += 1
    for base in bases:
        value = _mod_power(base, odd_power, number)
        if value == 1 or value == number - 1:
            continue
        for _ in range(1, two_power):
            value = value * value % number
            if value == number - 1:
                break
        else:
            return False
    return True


def _advance(value: int, c: int, modulus: int) -> int:
    return (value * value + c) % modulus


def _pollard_rho_customizable(
    number: int,
    x0: int,
    c: int,
    iterations_before_check: int = ITERATIONS_BEFORE_CHECK,
    iterations_cutoff: int = ITERATIONS_CUTOFF,
) -> int:
    """Mirror the pinned Brent routine, including its gcd==number return path."""
    x = x0
    x_start = 0
    y = 0
    remainder = 1
    current_gcd = 1
    max_iterations = 1

    while current_gcd == 1:
        y = x
        for _ in range(1, max_iterations):
            x = _advance(x, c, number)

        big_iteration = 0
        while big_iteration < max_iterations and current_gcd == 1:
            x_start = x
            small_iteration = 0
            while (
                small_iteration < iterations_before_check
                and small_iteration < max_iterations - big_iteration
            ):
                small_iteration += 1
                x = _advance(x, c, number)
                remainder = remainder * abs(x - y) % number
            current_gcd = _gcd(remainder, number)
            big_iteration += iterations_before_check

        max_iterations *= 2
        if max_iterations > iterations_cutoff:
            break

    if current_gcd == number:
        # The pinned source's recovery loop condition checks gcd==1, so it
        # does not execute on this path and the source returns number.
        pass
    return current_gcd


def _next_u32(state: int) -> int:
    return (LCG_MULTIPLIER * state + LCG_INCREMENT) & LCG_MASK


def _get_64bits(state: int) -> tuple[int, int]:
    state = _next_u32(state)
    high = state
    state = _next_u32(state)
    return (high << 32) | state, state


def _source_factor(number: int, seed: int, restart_limit: int) -> int:
    if _source_probable_prime(number):
        return number

    for _ in range(restart_limit):
        raw_x, seed = _get_64bits(seed)
        raw_c, seed = _get_64bits(seed)
        x0 = raw_x % (number - 3) + 2
        c = raw_c % (number - 2) + 1
        factor = _pollard_rho_customizable(number, x0, c)
        if factor not in (1, number):
            return factor
    return NO_FACTOR_RESULT


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the source factor, 0 after bounded restart exhaustion, or -1 if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != 3
    ):
        return INVALID_RESULT

    number, seed, restart_limit = values
    if not 2 <= number <= 1_000_000_000:
        return INVALID_RESULT
    if not 0 <= seed <= U32_MAX or not 1 <= restart_limit <= 16:
        return INVALID_RESULT
    return _source_factor(number, seed, restart_limit)
