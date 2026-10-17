"""Independent oracle for the bounded C++ magic-sequence enumeration."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_N = 11
FNV_OFFSET_BASIS = 14_695_981_039_346_656_037
FNV_PRIME = 1_099_511_628_211
U64_MASK = (1 << 64) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I64_RESULT_MASK = (1 << 63) - 1


def _magic_solutions(n: int) -> list[tuple[int, ...]]:
    """Enumerate the self-describing vectors via their count composition.

    Every magic vector has sum n because its entries count all n positions.
    Generating bounded weak compositions of n in lexicographic order is
    independent of the source's prefix-pruned vector traversal.
    """
    if n == 0:
        return [()]

    values = [0] * n
    solutions: list[tuple[int, ...]] = []

    def compose(index: int, remaining: int) -> None:
        if index == n:
            if remaining == 0:
                frequencies = [0] * n
                for value in values:
                    frequencies[value] += 1
                if frequencies == values:
                    solutions.append(tuple(values))
            return

        largest = min(n - 1, remaining)
        for value in range(largest + 1):
            values[index] = value
            compose(index + 1, remaining - value)

    compose(0, n)
    return solutions


def _fnv1a_byte(hash_value: int, value: int) -> int:
    return ((hash_value ^ value) * FNV_PRIME) & U64_MASK


def solution_count(n: int) -> int:
    """Return the number of retained rows for a valid ``n``."""
    if type(n) is not int or not 0 <= n <= MAX_N:
        raise ValueError("n must be an integer from 0 through 11")
    return len(_magic_solutions(n))


def magic_sequence_hash(n: int) -> int:
    """Return the low 63 bits of the count-framed FNV-1a result."""
    solutions = _magic_solutions(n)
    hash_value = _fnv1a_byte(FNV_OFFSET_BASIS, n)
    for byte in len(solutions).to_bytes(4, "little", signed=False):
        hash_value = _fnv1a_byte(hash_value, byte)
    for solution in solutions:
        for value in solution:
            hash_value = _fnv1a_byte(hash_value, value)
    return hash_value & I64_RESULT_MASK


def expected_result(values: Sequence[int]) -> int:
    """Validate `[n]` and return its deterministic enumeration hash."""
    if not isinstance(values, (list, tuple)) or len(values) != 1:
        return INVALID_RESULT
    n = values[0]
    if type(n) is not int or n < I64_MIN or n > I64_MAX or not 0 <= n <= MAX_N:
        return INVALID_RESULT
    return magic_sequence_hash(n)
