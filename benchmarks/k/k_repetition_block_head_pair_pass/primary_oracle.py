"""Bounded stage-one block-head pass for K-mismatch repetitions."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 24
MAX_K = 3
MAX_VALID_INPUT_LENGTH = 26
MAX_PARSEABLE_INPUT_LENGTH = 27
MAX_RECORDS = 1222
MAX_OUTPUT_BYTES = 8 + 32 * MAX_RECORDS
WORKSPACE_BYTES = 8192


def _parse(values: Sequence[int] | None, input_length: int | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values):
        return None
    n, budget = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= budget <= MAX_K or length != n + 2:
        return None
    text = list(values[2:])
    if any(x < 0 or x > 4 for x in text) or text[-1] in text[:-1]:
        return None
    return text, budget


def _lz_factors(text: Sequence[int]) -> list[tuple[int, int]]:
    """Copy-overlap LZ factors as half-open text intervals."""
    n = len(text)
    factors: list[tuple[int, int]] = []
    pos = 0
    while pos < n:
        longest = 0
        for earlier in range(pos):
            length = 0
            while pos + length < n and earlier + length < n and text[earlier + length] == text[pos + length]:
                length += 1
            longest = max(longest, length)
        end = min(n, pos + longest + 1)
        factors.append((pos, end))
        pos = end
    return factors


def _forward(text: Sequence[int], center: int, period: int, allowed: int) -> int:
    left = center - period
    limit = min(len(text) - left, len(text) - center)
    errors = 0
    for offset in range(limit):
        if text[left + offset] != text[center + offset]:
            errors += 1
            if errors > allowed:
                return offset
    return limit


def _backward(text: Sequence[int], center: int, period: int, allowed: int) -> int:
    limit = min(center - period, center)
    errors = 0
    for offset in range(limit):
        if text[center - period - 1 - offset] != text[center - 1 - offset]:
            errors += 1
            if errors > allowed:
                return offset
    return limit


def _algorithm1_at(text: Sequence[int], center: int, budget: int):
    """Algorithm 1, with direct bounded forward/backward extensions."""
    n = len(text)
    if center < 1 or center + 1 >= n:
        return
    for period in range(1, center + 1):
        for right_budget in range(budget + 1):
            left_budget = budget - right_budget
            fwd = _forward(text, center, period, right_budget)
            back = _backward(text, center, period, left_budget)
            if fwd <= period and fwd + back >= period:
                yield center - period - back, center + fwd - 1, period

    reversed_text = list(reversed(text))
    reverse_center = n - 1 - center
    for period in range(1, reverse_center + 1):
        for right_budget in range(budget + 1):
            left_budget = budget - right_budget
            fwd = _forward(reversed_text, reverse_center, period, right_budget)
            back = _backward(reversed_text, reverse_center, period, left_budget)
            if fwd <= period and fwd + back >= period:
                reverse_start = reverse_center - period - back
                reverse_end = reverse_center + fwd - 1
                yield n - 1 - reverse_end, n - 1 - reverse_start, period


def _pair_contexts(text: Sequence[int], factors: Sequence[tuple[int, int]], budget: int):
    block_size = budget + 2
    block_count = (len(factors) + block_size - 1) // block_size
    for block_index in range(block_count - 1):
        first_factor = block_index * block_size
        next_factor = min(len(factors), first_factor + block_size)
        following_factor = min(len(factors), next_factor + block_size)
        first_head = factors[next_factor - 1][1] - 1
        following_head = factors[following_factor - 1][1] - 1
        pair_start = factors[first_factor][0]
        pair_end = factors[following_factor - 1][1]
        pair_length = pair_end - pair_start
        context_start = max(0, pair_start - pair_length)
        yield context_start, pair_end, first_head, following_head


def _records(text: Sequence[int], budget: int) -> list[tuple[int, int, int, int]]:
    found: set[tuple[int, int, int, int]] = set()
    factors = _lz_factors(text)
    for context_start, context_end, head, next_head in _pair_contexts(text, factors, budget):
        local = text[context_start:context_end]
        center = head - context_start
        for lo, hi, period in _algorithm1_at(local, center, budget):
            if lo > center + 1 or hi < center - 1:
                continue
            if lo <= next_head - context_start + 1 and hi >= next_head - context_start - 1:
                continue
            start = context_start + lo
            end = context_start + hi
            mismatches = sum(text[i] != text[i + period] for i in range(start, end - period + 1))
            found.add((start, end - start + 1, period, mismatches))
    return sorted(found, key=lambda item: (item[0], item[1], item[2], item[3]))


def _payload(text: Sequence[int], budget: int) -> bytes:
    records = _records(text, budget)
    out = bytearray(len(records).to_bytes(8, "little", signed=True))
    for record in records:
        for value in record:
            out.extend(value.to_bytes(8, "little", signed=True))
    return bytes(out)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if input_length is not None and (type(input_length) is not int
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    text, budget = parsed
    payload = _payload(text, budget)
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
