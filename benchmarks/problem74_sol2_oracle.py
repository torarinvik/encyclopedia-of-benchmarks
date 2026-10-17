"""Source-faithful oracle for the second Project Euler 74 solution."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_CHAIN_LENGTH = 1
MAX_CHAIN_LENGTH = 60
MIN_NUMBER_LIMIT = 1
MAX_NUMBER_LIMIT = 1_000_000
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1
DIGIT_FACTORIALS = (1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880)


def digit_factorial_sum(number: int) -> int:
    """Return the source's decimal-digit factorial successor for a nonnegative integer."""
    if type(number) is not int or number < 0:
        raise ValueError("number must be a nonnegative integer")
    return sum(DIGIT_FACTORIALS[int(digit)] for digit in str(number))


def expected_result(values: Sequence[int]) -> int:
    """Return the bounded sol2 chain count, or the -1 invalid-input sentinel."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) != MAX_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT

    chain_length, number_limit = values
    if not MIN_CHAIN_LENGTH <= chain_length <= MAX_CHAIN_LENGTH:
        return INVALID_RESULT
    if not MIN_NUMBER_LIMIT <= number_limit <= MAX_NUMBER_LIMIT:
        return INVALID_RESULT

    chains_counter = 0
    chain_sets_lengths: dict[int, int] = {}
    for start_chain_element in range(1, number_limit):
        chain_set: set[int] = set()
        chain_set_length = 0
        chain_element = start_chain_element
        while (
            chain_element not in chain_sets_lengths
            and chain_element not in chain_set
            and chain_set_length <= chain_length
        ):
            chain_set.add(chain_element)
            chain_set_length += 1
            chain_element = digit_factorial_sum(chain_element)
        if chain_element in chain_sets_lengths:
            chain_set_length += chain_sets_lengths[chain_element]

        chain_sets_lengths[start_chain_element] = chain_set_length
        if chain_set_length == chain_length:
            chains_counter += 1

    return chains_counter
