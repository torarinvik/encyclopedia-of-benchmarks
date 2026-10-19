"""Independent oracle for the bounded MiBench automotive-bitcount workload."""

from __future__ import annotations

from functools import lru_cache

MAX_ITERATIONS = 1_125_000
ALGORITHM_NAMES = (
    "Optimized 1 bit/loop counter",
    "Ratko's mystery algorithm",
    "Recursive bit count by nybbles",
    "Non-recursive bit count by nybbles",
    "Non-recursive bit count by bytes (BW)",
    "Non-recursive bit count by bytes (AR)",
    "Shift and count bits",
)
REFERENCE_CHECKSUMS = (13254056, 13255501, 13257159, 13246703, 13250340, 13249450, 13257011)
_NIBBLE_BITS = (0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4)
_INITIAL_SEEDS = (16839, 18985, 21520, 3905, 10113, 8672, 21285)


def _kernsighan(value: int) -> int:
    count = 0
    while value:
        value &= value - 1
        count += 1
    return count


def _parallel_32(value: int) -> int:
    value = ((value & 0xAAAAAAAA) >> 1) + (value & 0x55555555)
    value = ((value & 0xCCCCCCCC) >> 2) + (value & 0x33333333)
    value = ((value & 0xF0F0F0F0) >> 4) + (value & 0x0F0F0F0F)
    value = ((value & 0xFF00FF00) >> 8) + (value & 0x00FF00FF)
    value = ((value & 0xFFFF0000) >> 16) + (value & 0x0000FFFF)
    return value


def _recursive_nybbles(value: int) -> int:
    count = _NIBBLE_BITS[value & 0xF]
    return count if value >> 4 == 0 else count + _recursive_nybbles(value >> 4)


def _fixed_nybbles(value: int) -> int:
    return sum(_NIBBLE_BITS[(value >> shift) & 0xF] for shift in range(0, 32, 4))


def _bw_bytes(value: int) -> int:
    return sum(_NIBBLE_BITS[(value >> shift) & 0xF]
               + _NIBBLE_BITS[(value >> (shift + 4)) & 0xF]
               for shift in range(0, 32, 8))


def _ar_bytes(value: int) -> int:
    total = 0
    for byte_index in range(4):
        byte = (value >> (8 * byte_index)) & 0xFF
        total += _NIBBLE_BITS[byte & 0xF] + _NIBBLE_BITS[byte >> 4]
    return total


def _shift_count(value: int) -> int:
    count = 0
    for _ in range(64):
        if value == 0:
            break
        count += value & 1
        value >>= 1
    return count


_COUNTERS = (_kernsighan, _parallel_32, _recursive_nybbles, _fixed_nybbles,
             _bw_bytes, _ar_bytes, _shift_count)


@lru_cache(maxsize=128)
def algorithm_checksums(iterations: int) -> tuple[int, ...] | None:
    """Return the seven source-order totals, or None outside the bounded input."""
    if type(iterations) is not int or not 0 <= iterations <= MAX_ITERATIONS:
        return None
    totals: list[int] = []
    for initial_seed, counter in zip(_INITIAL_SEEDS, _COUNTERS, strict=True):
        seed = initial_seed
        total = 0
        for _ in range(iterations):
            total += counter(seed)
            seed += 13
        totals.append(total)
    return tuple(totals)


def expected_result(iterations: int) -> int:
    """Return the ordered weighted checksum used by the scalar suite."""
    totals = algorithm_checksums(iterations)
    if totals is None:
        return -1
    return sum((index + 1) * total for index, total in enumerate(totals))
