"""Bounded copy-overlap LZ binary-division repetition kernel."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_K = 3
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 91_400
WORKSPACE_BYTES = 8_192
MAX_PERIODS = MAX_N // 2 + 1
BIT_WORDS = (MAX_N * MAX_N * MAX_PERIODS + 63) // 64


def _parse(values: Sequence[int] | None, input_length: int | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values):
        return None
    n, budget = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= budget <= MAX_K or size != n + 2:
        return None
    text = list(values[2:])
    if any(symbol < 0 or symbol > 4 for symbol in text):
        return None
    if text[-1] in text[:-1]:
        return None
    return text, budget


def _copy_overlap_factors(text: Sequence[int]) -> list[tuple[int, int]]:
    """Return half-open LZ factors, allowing a prior copy to overlap its source."""
    n = len(text)
    factors: list[tuple[int, int]] = []
    start = 0
    while start < n:
        best = 0
        for earlier in range(start):
            length = 0
            while (start + length < n and earlier + length < n
                   and text[earlier + length] == text[start + length]):
                length += 1
            if length > best:
                best = length
        end = min(n, start + best + 1)
        factors.append((start, end))
        start = end
    return factors


def _lp(text: Sequence[int], center: int, period: int, budget: int) -> int:
    left = center - period
    limit = min(len(text) - left, len(text) - center)
    mismatches = 0
    for length in range(limit):
        if text[left + length] != text[center + length]:
            mismatches += 1
            if mismatches > budget:
                return length
    return limit


def _ls(text: Sequence[int], center: int, period: int, budget: int) -> int:
    limit = min(center - period, center)
    mismatches = 0
    for length in range(limit):
        if text[center - period - 1 - length] != text[center - 1 - length]:
            mismatches += 1
            if mismatches > budget:
                return length
    return limit


def _at_center(text: Sequence[int], center: int, budget: int):
    """Algorithm 1 from the report, using bounded direct LCE extensions."""
    n = len(text)
    if center < 1 or center + 1 >= n:
        return
    for period in range(1, center + 1):
        for right_budget in range(budget + 1):
            left_budget = budget - right_budget
            forward = _lp(text, center, period, right_budget)
            backward = _ls(text, center, period, left_budget)
            if forward <= period and forward + backward >= period:
                start = center - period - backward
                end = center + forward - 1
                if end - start + 1 >= 2 * period:
                    yield start, end, period

    reversed_text = list(reversed(text))
    reverse_center = n - 1 - center
    for period in range(1, reverse_center + 1):
        for right_budget in range(budget + 1):
            left_budget = budget - right_budget
            forward = _lp(reversed_text, reverse_center, period, right_budget)
            backward = _ls(reversed_text, reverse_center, period, left_budget)
            if forward <= period and forward + backward >= period:
                reverse_start = reverse_center - period - backward
                reverse_end = reverse_center + forward - 1
                if reverse_end - reverse_start + 1 >= 2 * period:
                    yield n - 1 - reverse_end, n - 1 - reverse_start, period


def _candidate_bits(text: Sequence[int], budget: int) -> list[int]:
    bits = [0] * BIT_WORDS
    factors = _copy_overlap_factors(text)
    block_size = budget + 2

    def mark_node(first: int, last: int) -> None:
        if first >= last:
            return
        middle = first + (last - first) // 2
        block_lo = factors[first][0]
        block_hi = factors[last][1]
        center = factors[middle][1] - 1
        last_head = factors[last][1] - 1
        local = text[block_lo:block_hi]
        local_center = center - block_lo
        for local_start, local_end, period in _at_center(local, local_center, budget):
            start = block_lo + local_start
            end = block_lo + local_end
            if start == block_lo or end >= len(text):
                continue
            if start <= last_head + 1 and end >= last_head - 1:
                continue
            if end - start + 1 < 2 * period:
                continue
            index = ((start * MAX_N + end) * MAX_PERIODS) + period
            bits[index // 64] |= 1 << (index % 64)
        mark_node(first, middle)
        mark_node(middle + 1, last)

    for block_start in range(0, len(factors), block_size):
        block_end = min(len(factors), block_start + block_size) - 1
        mark_node(block_start, block_end)
    return bits


def _payload(text: Sequence[int], budget: int) -> bytes:
    bits = _candidate_bits(text, budget)
    records: list[tuple[int, int, int, int]] = []
    n = len(text)
    for start in range(n):
        for length in range(2, n - start + 1):
            end = start + length - 1
            for period in range(1, length // 2 + 1):
                index = ((start * MAX_N + end) * MAX_PERIODS) + period
                if bits[index // 64] & (1 << (index % 64)):
                    mismatches = sum(text[i] != text[i + period]
                                     for i in range(start, end - period + 1))
                    records.append((start, length, period, mismatches))
    output = bytearray(len(records).to_bytes(8, "little", signed=True))
    for record in records:
        for value in record:
            output.extend(value.to_bytes(8, "little", signed=True))
    return bytes(output)


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
