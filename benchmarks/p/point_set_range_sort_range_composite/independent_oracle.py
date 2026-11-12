"""Independent verifier using priority IDs and selection sorting."""

from __future__ import annotations

from collections.abc import Sequence

MOD = 998_244_353
MAX_N = 16
MAX_Q = 32
MAX_LENGTH = 210
INVALID = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    words: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID
    if not isinstance(words, (list, tuple)) or len(words) < 2 or len(words) > MAX_LENGTH:
        return INVALID
    if any(type(word) is not int or word < I64_MIN or word > I64_MAX for word in words):
        return INVALID
    size = len(words) if input_length is None else input_length
    if type(size) is not int or size != len(words):
        return INVALID
    n, q = words[0], words[1]
    if n < 1 or n > MAX_N or q < 1 or q > MAX_Q or len(words) < 2 + 3 * n:
        return INVALID

    order: list[int] = []
    affine_by_priority: dict[int, tuple[int, int]] = {}
    all_priorities: set[int] = set()
    pos = 2
    for _ in range(n):
        priority, multiplier, offset = words[pos], words[pos + 1], words[pos + 2]
        pos += 3
        if (priority < 0 or priority > 1_000_000_000 or priority in all_priorities
                or multiplier < 1 or multiplier >= MOD or offset < 0 or offset >= MOD):
            return INVALID
        all_priorities.add(priority)
        order.append(priority)
        affine_by_priority[priority] = (multiplier, offset)

    checksum = 0
    query_ordinal = 0
    for _ in range(q):
        if pos >= len(words):
            return INVALID
        code = words[pos]
        pos += 1
        if code == 0:
            if pos + 4 > len(words):
                return INVALID
            index, priority, multiplier, offset = words[pos:pos + 4]
            pos += 4
            if (index < 0 or index >= n or priority < 0 or priority > 1_000_000_000
                    or priority in all_priorities or multiplier < 1 or multiplier >= MOD
                    or offset < 0 or offset >= MOD):
                return INVALID
            all_priorities.add(priority)
            old_priority = order[index]
            del affine_by_priority[old_priority]
            order[index] = priority
            affine_by_priority[priority] = (multiplier, offset)
        elif code == 1:
            if pos + 3 > len(words):
                return INVALID
            left, right, argument = words[pos], words[pos + 1], words[pos + 2]
            pos += 3
            if left < 0 or left >= right or right > n or argument < 0 or argument >= MOD:
                return INVALID
            result = argument
            for priority in order[left:right]:
                multiplier, offset = affine_by_priority[priority]
                result = (result * multiplier + offset) % MOD
            query_ordinal += 1
            checksum = (checksum + query_ordinal * result) % MOD
        elif code == 2 or code == 3:
            if pos + 2 > len(words):
                return INVALID
            left, right = words[pos], words[pos + 1]
            pos += 2
            if left < 0 or left >= right or right > n:
                return INVALID
            for first in range(left, right):
                best = first
                for candidate in range(first + 1, right):
                    if ((code == 2 and order[candidate] < order[best])
                            or (code == 3 and order[candidate] > order[best])):
                        best = candidate
                if best != first:
                    order[first], order[best] = order[best], order[first]
        else:
            return INVALID
    return checksum if pos == len(words) else INVALID
