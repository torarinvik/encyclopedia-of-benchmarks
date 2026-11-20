"""Pairing-enumeration oracle independent of Irving's list reductions."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_PARSEABLE_INPUT_LENGTH = 58


def _validated_preferences(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values:
        return None
    n = values[0]
    if type(n) is not int or n < 2 or n > 8 or n % 2:
        return None
    if len(values) != 1 + n * (n - 1):
        return None
    rank = [[n] * n for _ in range(n)]
    cursor = 1
    for person in range(n):
        seen = set()
        for position in range(n - 1):
            other = values[cursor]
            cursor += 1
            if (type(other) is not int or not 0 <= other < n
                    or other == person or other in seen):
                return None
            seen.add(other)
            rank[person][other] = position
        if len(seen) != n - 1:
            return None
    return n, rank


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _validated_preferences(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, rank = decoded
    partner = [-1] * n

    def has_stable_completion(remaining_mask: int) -> bool:
        if remaining_mask == 0:
            for first in range(n):
                for second in range(first + 1, n):
                    if partner[first] == second:
                        continue
                    if (rank[first][second] < rank[first][partner[first]]
                            and rank[second][first] < rank[second][partner[second]]):
                        return False
            return True

        first = next(person for person in range(n) if remaining_mask & (1 << person))
        rest = remaining_mask & ~(1 << first)
        for second in range(first + 1, n):
            if rest & (1 << second):
                partner[first] = second
                partner[second] = first
                if has_stable_completion(rest & ~(1 << second)):
                    return True
                partner[second] = -1
        partner[first] = -1
        return False

    return int(has_stable_completion((1 << n) - 1))
