"""Bounded within-factor copy propagation for K-mismatch repetitions."""

from __future__ import annotations

from bisect import insort
from collections.abc import Sequence

MAX_N = 16
MAX_K = 3
MAX_SYMBOL = 5
MAX_RECORDS = 372
MAX_VALID_INPUT_LENGTH = 1556
MAX_PARSEABLE_INPUT_LENGTH = 1557
MAX_OUTPUT_BYTES = 8 + 32 * MAX_RECORDS
WORKSPACE_BYTES = 16384

Record = tuple[int, int, int, int]  # start, end-exclusive, period, mismatches


def _lce(text: Sequence[int], left: int, right: int) -> int:
    length = 0
    while left + length < len(text) and right + length < len(text) and text[left + length] == text[right + length]:
        length += 1
    return length


def _validate_factors(text: Sequence[int], factors: Sequence[tuple[int, int, int]]) -> bool:
    n = len(text)
    if not factors or len(factors) > n:
        return False
    position = 0
    for factor_index, (start, end, copy_start) in enumerate(factors):
        if start != position or not start < end <= n:
            return False
        if factor_index == 0:
            if (start, end, copy_start) != (0, 1, -1):
                return False
            position = end
            continue
        longest = 0
        for earlier in range(start):
            longest = max(longest, _lce(text, earlier, start))
        expected_end = min(n, start + longest + 1)
        if end != expected_end:
            return False
        prefix_length = end - start - 1
        if prefix_length == 0:
            if copy_start != -1:
                return False
        elif not (0 <= copy_start < start and _lce(text, copy_start, start) == prefix_length):
            return False
        position = end
    return position == n


def _record_mismatches(text: Sequence[int], start: int, end: int, period: int) -> int:
    return sum(text[index] != text[index + period] for index in range(start, end - period))


def _valid_seed(text: Sequence[int], budget: int, record: Record) -> bool:
    start, end, period, mismatches = record
    n = len(text)
    if not (0 <= start < end <= n and 1 <= period <= n // 2 and end - start >= 2 * period):
        return False
    actual = _record_mismatches(text, start, end, period)
    if actual != mismatches or actual > budget:
        return False
    if start > 0 and actual + (text[start - 1] != text[start + period - 1]) <= budget:
        return False
    if end < n and actual + (text[end - period] != text[end]) <= budget:
        return False
    return True


def _parse(values: Sequence[int] | None, input_length: int | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values):
        return None
    n, budget = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= budget <= MAX_K or length < n + 3:
        return None
    cursor = 2
    text = list(values[cursor:cursor + n])
    cursor += n
    if any(symbol < 0 or symbol > MAX_SYMBOL for symbol in text) or text[-1] in text[:-1]:
        return None
    factor_count = values[cursor]
    cursor += 1
    if not 1 <= factor_count <= n or cursor + 3 * factor_count >= length:
        return None
    factors: list[tuple[int, int, int]] = []
    for _ in range(factor_count):
        factors.append((values[cursor], values[cursor + 1], values[cursor + 2]))
        cursor += 3
    if cursor >= length:
        return None
    seed_count = values[cursor]
    cursor += 1
    if not 0 <= seed_count <= MAX_RECORDS or cursor + 4 * seed_count != length:
        return None
    seeds: list[Record] = []
    for _ in range(seed_count):
        seeds.append((values[cursor], values[cursor + 1], values[cursor + 2], values[cursor + 3]))
        cursor += 4
    if not _validate_factors(text, factors) or any(not _valid_seed(text, budget, record) for record in seeds):
        return None
    return text, budget, factors, seeds


def _propagate(text: Sequence[int], factors: Sequence[tuple[int, int, int]], seeds: Sequence[Record]) -> list[Record]:
    # A sorted start/end list is the bounded analogue of the source's buckets.
    records: list[Record] = []
    known: set[tuple[int, int, int]] = set()
    generated: set[tuple[int, int, int]] = set()

    def add(record: Record, is_generated: bool) -> None:
        key = record[:3]
        if key in known:
            return
        known.add(key)
        insort(records, record)
        if is_generated:
            generated.add(key)

    for seed in seeds:
        add(seed, False)

    for factor_start, factor_end, copy_start in factors:
        prefix_length = factor_end - factor_start - 1
        if prefix_length <= 0:
            continue
        delta = factor_start - copy_start
        copy_end = copy_start + prefix_length
        # The last factor character is its head.  A copied record may not
        # include the head or the adjacent character immediately before it.
        for target_start in range(factor_start + 1, factor_end - 1):
            source_start = target_start - delta
            index = 0
            while index < len(records) and records[index][0] < source_start:
                index += 1
            while index < len(records) and records[index][0] == source_start:
                source = records[index]
                if source[1] > copy_end:
                    break  # each start bucket is sorted by end
                target_end = source[1] + delta
                if target_end <= factor_end - 2:
                    add((target_start, target_end, source[2], source[3]), True)
                index += 1

    return sorted((record for record in records if record[:3] in generated),
                  key=lambda record: (record[0], record[1], record[2], record[3]))


def _encode(records: Sequence[Record]) -> bytes:
    payload = bytearray(len(records).to_bytes(8, "little", signed=True))
    for record in records:
        for value in record:
            payload.extend(value.to_bytes(8, "little", signed=True))
    return bytes(payload)


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
    text, _, factors, seeds = parsed
    payload = _encode(_propagate(text, factors, seeds))
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

