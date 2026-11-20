"""Direct palindrome-table and prefix-DP reference, independent of eertrees."""
from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (
    ALPHABET_SIZE, I64_MAX, I64_MIN, MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH, MAX_TEXT_LENGTH,
)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    text = list(values[1:])
    if any(not 0 <= symbol < ALPHABET_SIZE for symbol in text):
        return None
    return text


def _solve(text: list[int]) -> list[int]:
    n = len(text)
    palindrome = [[False] * n for _ in range(n)]
    for start in range(n - 1, -1, -1):
        for end in range(start, n):
            palindrome[start][end] = (
                text[start] == text[end]
                and (end - start <= 1 or palindrome[start + 1][end - 1])
            )

    infinity = n + 1
    dp = [0] + [infinity] * n
    predecessor = [0] * (n + 1)
    for end in range(1, n + 1):
        best_start = end
        for start in range(end):
            if not palindrome[start][end - 1]:
                continue
            candidate = dp[start] + 1
            if candidate < dp[end] or (candidate == dp[end] and start < best_start):
                dp[end] = candidate
                best_start = start
        predecessor[end] = best_start
    pieces: list[int] = []
    end = n
    while end > 0:
        start = predecessor[end]
        pieces.append(end - start)
        end = start
    pieces.reverse()
    return [len(pieces), *pieces]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    text = _decode(values, input_length, input_is_null)
    if text is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", word) for word in _solve(text))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(payload) > effective_capacity:
        return -2, b""
    return len(payload), payload
