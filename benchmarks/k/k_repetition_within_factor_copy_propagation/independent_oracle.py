"""Independent scan-based oracle for within-factor record propagation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_K = 3
MAX_VALID_INPUT_LENGTH = 1556
MAX_RECORDS = 372
MAX_PARSEABLE_INPUT_LENGTH = 1557
MAX_OUTPUT_BYTES = 8 + 32 * MAX_RECORDS
WORKSPACE_BYTES = 16384

Record = tuple[int, int, int, int]


def _has_occurrence(text: Sequence[int], pattern: Sequence[int], limit: int) -> bool:
    if not pattern:
        return True
    for start in range(limit):
        if start + len(pattern) <= len(text) and all(
            text[start + offset] == pattern[offset] for offset in range(len(pattern))
        ):
            return True
    return False


def _factor_rows_are_valid(text: Sequence[int], rows: Sequence[tuple[int, int, int]]) -> bool:
    position = 1
    if not rows or len(rows) > len(text) or rows[0] != (0, 1, -1):
        return False
    for start, end, copy_start in rows[1:]:
        if start != position or not start < end <= len(text):
            return False
        prefix = text[start:end - 1]
        whole = text[start:end]
        if prefix:
            if not (0 <= copy_start < start and
                    text[copy_start:copy_start + len(prefix)] == prefix):
                return False
        elif copy_start != -1:
            return False
        if _has_occurrence(text, whole, start):
            return False
        position = end
    return position == len(text)


def _error_count(text: Sequence[int], start: int, end: int, period: int) -> int:
    errors = 0
    for index in range(start, end - period):
        if text[index] != text[index + period]:
            errors += 1
    return errors


def _seed_is_valid(text: Sequence[int], budget: int, item: Record) -> bool:
    start, end, period, errors = item
    if (not 0 <= start < end <= len(text) or not 1 <= period <= len(text) // 2
            or end - start < 2 * period):
        return False
    actual = _error_count(text, start, end, period)
    if actual != errors or actual > budget:
        return False
    if start and actual + (text[start - 1] != text[start - 1 + period]) <= budget:
        return False
    if end < len(text) and actual + (text[end - period] != text[end]) <= budget:
        return False
    return True


def _decode(values: Sequence[int] | None, input_length: int | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    n, budget = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= budget <= MAX_K or actual_length < n + 3:
        return None
    text = list(values[2:2 + n])
    if any(symbol < 0 or symbol > 5 for symbol in text) or text[-1] in text[:-1]:
        return None
    cursor = 2 + n
    factor_count = values[cursor]
    cursor += 1
    if not 1 <= factor_count <= n or cursor + 3 * factor_count >= actual_length:
        return None
    factors = []
    for _ in range(factor_count):
        factors.append((values[cursor], values[cursor + 1], values[cursor + 2]))
        cursor += 3
    if cursor >= actual_length:
        return None
    seed_count = values[cursor]
    cursor += 1
    if not 0 <= seed_count <= MAX_RECORDS or cursor + 4 * seed_count != actual_length:
        return None
    seeds = []
    for _ in range(seed_count):
        seeds.append((values[cursor], values[cursor + 1], values[cursor + 2], values[cursor + 3]))
        cursor += 4
    if not _factor_rows_are_valid(text, factors):
        return None
    if any(not _seed_is_valid(text, budget, item) for item in seeds):
        return None
    return text, factors, seeds


def _scan_all_seeds(text: Sequence[int], factors: Sequence[tuple[int, int, int]],
                    seeds: Sequence[Record]) -> list[Record]:
    active: set[Record] = set(seeds)
    propagated: set[Record] = set()
    for factor_start, factor_end, copy_start in factors:
        copied_length = factor_end - factor_start - 1
        if copied_length <= 0:
            continue
        shift = factor_start - copy_start
        copied_end = copy_start + copied_length
        for target in range(factor_start + 1, factor_end - 1):
            source = target - shift
            # This oracle scans the complete record set instead of consulting
            # the primary's sorted per-start bucket.
            pending = [record for record in active
                       if record[0] == source and record[1] <= copied_end]
            for _, old_end, period, errors in pending:
                new_end = old_end + shift
                if new_end <= factor_end - 2:
                    item = (target, new_end, period, errors)
                    if item not in active:
                        active.add(item)
                        propagated.add(item)
    return sorted(propagated, key=lambda item: (item[0], item[1], item[2], item[3]))


def _serialize(records: Sequence[Record]) -> bytes:
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
    parsed = _decode(values, input_length)
    if parsed is None:
        return -1, b""
    text, factors, seeds = parsed
    payload = _serialize(_scan_all_seeds(text, factors, seeds))
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

