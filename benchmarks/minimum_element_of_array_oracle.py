"""Reference for seeded randomized quickselect over a bounded distinct array."""
MAX_INPUT_LENGTH = 131
MAX_ARRAY_LENGTH = 128

def _next(state: int) -> tuple[int, int]:
    x = state & 0xFFFFFFFF
    x ^= (x << 13) & 0xFFFFFFFF
    x ^= x >> 17
    x ^= (x << 5) & 0xFFFFFFFF
    x &= 0xFFFFFFFF
    return (x or 0x9E3779B9), (x or 0x9E3779B9)

def _select(a: list[int], lo: int, hi: int, k: int, state: int) -> int:
    if lo == hi:
        return a[lo]
    state, draw = _next(state)
    pivot_index = lo + draw % (hi - lo + 1)
    a[pivot_index], a[hi] = a[hi], a[pivot_index]
    pivot = a[hi]
    i = lo
    for j in range(lo, hi):
        if a[j] <= pivot:
            a[i], a[j] = a[j], a[i]
            i += 1
    a[i], a[hi] = a[hi], a[i]
    pivot_rank = i - lo + 1
    if k == pivot_rank:
        return a[i]
    if k < pivot_rank:
        return _select(a, lo, i - 1, k, state)
    return _select(a, i + 1, hi, k - pivot_rank, state)

def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1
    n, k, seed, *array = values
    if (not 1 <= n <= MAX_ARRAY_LENGTH or len(array) != n or not 1 <= k <= n
            or not 0 <= seed <= 2_147_483_647
            or any(not -1_000_000 <= x <= 1_000_000 for x in array)
            or len(set(array)) != len(array)):
        return -1
    return _select(array, 0, n - 1, k, seed or 0x9E3779B9)
