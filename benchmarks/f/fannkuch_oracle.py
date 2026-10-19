"""Independent bounded oracle for the Benchmark Game fannkuch C variant."""

from __future__ import annotations

MIN_N = 1
MAX_N = 8
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def _maximum_flips(n: int) -> int:
    """Follow the source counter permutation order and optimized flip loop."""
    perm1 = list(range(n))
    perm = [0] * n
    count = [0] * n
    r = n
    flips_max = 0

    while True:
        while r != 1:
            count[r - 1] = r
            r -= 1

        if perm1[0] != 0 and perm1[n - 1] != n - 1:
            perm[1:] = perm1[1:]
            k = perm1[0]
            flips = 0
            while True:
                i, j = 1, k - 1
                while i < j:
                    perm[i], perm[j] = perm[j], perm[i]
                    i += 1
                    j -= 1
                flips += 1
                j = perm[k]
                perm[k] = k
                k = j
                if k == 0:
                    break
            if flips_max < flips:
                flips_max = flips

        while True:
            if r == n:
                return flips_max
            first = perm1[0]
            for i in range(r):
                perm1[i] = perm1[i + 1]
            perm1[r] = first
            count[r] -= 1
            if count[r] > 0:
                break
            r += 1


def expected_result(values, input_is_null: bool = False, input_length: int | None = None) -> int:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or len(values) != 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT
    n = values[0]
    if type(n) is not int or not MIN_N <= n <= MAX_N:
        return INVALID_RESULT
    return _maximum_flips(n)
