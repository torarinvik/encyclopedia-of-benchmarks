"""Primary indexed-marking reference for the Sieve of Sundaram."""

from __future__ import annotations

MAX_LIMIT = 4096


def prime_count(limit: int) -> int:
    if type(limit) is not int or not 0 <= limit <= MAX_LIMIT:
        return -1
    if limit < 2:
        return 0
    max_index = (limit - 1) // 2
    composite = [False] * (max_index + 1)
    i = 1
    while 2 * i * (i + 1) <= max_index:
        j = i
        while True:
            index = i + j + 2 * i * j
            if index > max_index:
                break
            composite[index] = True
            j += 1
        i += 1
    return 1 + sum(not composite[index] for index in range(1, max_index + 1))
