"""Exhaustive factor-block oracle for the bounded binary-division kernel."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_K = 3
MAX_PARSEABLE_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 91_400
WORKSPACE_BYTES = 8_192


def _frame(values: Sequence[int] | None, input_length: int | None):
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
    if any(symbol < 0 or symbol > 4 for symbol in text) or text[-1] in text[:-1]:
        return None
    return text, budget


def _factors_by_occurrence_search(text: Sequence[int]) -> list[tuple[int, int]]:
    """Find each shortest new factor by testing all earlier substring starts."""
    n = len(text)
    factors: list[tuple[int, int]] = []
    start = 0
    while start < n:
        chosen_end = n
        for end in range(start + 1, n + 1):
            candidate = tuple(text[start:end])
            occurred = False
            for earlier in range(start):
                if tuple(text[earlier:earlier + len(candidate)]) == candidate:
                    occurred = True
                    break
            if not occurred:
                chosen_end = end
                break
        factors.append((start, chosen_end))
        start = chosen_end
    return factors


def _binary_nodes(factors: Sequence[tuple[int, int]], budget: int):
    block_size = budget + 2

    def visit(first: int, last: int):
        if first >= last:
            return
        middle = first + (last - first) // 2
        yield factors[first][0], factors[last][1], factors[middle][1] - 1, factors[last][1] - 1
        yield from visit(first, middle)
        yield from visit(middle + 1, last)

    result = []
    for block_start in range(0, len(factors), block_size):
        block_end = min(len(factors), block_start + block_size) - 1
        result.extend(visit(block_start, block_end))
    return result


def _is_maximal(text: Sequence[int], lo: int, hi: int, start: int, end: int,
                period: int, budget: int, mismatches: int) -> bool:
    if start > lo:
        left_added = text[start - 1] != text[start - 1 + period]
        if mismatches + int(left_added) <= budget:
            return False
    if end < hi - 1:
        right_added = text[end + 1 - period] != text[end + 1]
        if mismatches + int(right_added) <= budget:
            return False
    return True


def _direct_payload(text: Sequence[int], budget: int) -> bytes:
    factors = _factors_by_occurrence_search(text)
    records: set[tuple[int, int, int, int]] = set()
    for lo, hi, center, last_head in _binary_nodes(factors, budget):
        for start in range(lo + 1, hi):
            for end in range(start + 1, hi):
                if start <= center + 1 and end >= center - 1:
                    pass
                else:
                    continue
                if start <= last_head + 1 and end >= last_head - 1:
                    continue
                for period in range(1, (end - start + 1) // 2 + 1):
                    mismatches = sum(text[i] != text[i + period]
                                     for i in range(start, end - period + 1))
                    if mismatches <= budget and _is_maximal(
                            text, lo, hi, start, end, period, budget, mismatches):
                        records.add((start, end - start + 1, period, mismatches))
    ordered = sorted(records, key=lambda item: (item[0], item[1], item[2], item[3]))
    output = bytearray(len(ordered).to_bytes(8, "little", signed=True))
    for record in ordered:
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
    parsed = _frame(values, input_length)
    if parsed is None:
        return -1, b""
    text, budget = parsed
    payload = _direct_payload(text, budget)
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
