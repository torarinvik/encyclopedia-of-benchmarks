"""Direct interval/period oracle for the bounded block-head pass."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 24
MAX_K = 3
MAX_PARSEABLE_INPUT_LENGTH = 27
MAX_RECORDS = 1222
MAX_OUTPUT_BYTES = 8 + 32 * MAX_RECORDS
WORKSPACE_BYTES = 8192


def _frame(values: Sequence[int] | None, input_length: int | None):
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
    word = list(values[2:])
    if any(x < 0 or x > 4 for x in word) or word[-1] in word[:-1]:
        return None
    return word, budget


def _factor_by_first_novel_prefix(word: Sequence[int]) -> list[tuple[int, int]]:
    factors: list[tuple[int, int]] = []
    start = 0
    while start < len(word):
        chosen = len(word)
        for stop in range(start + 1, len(word) + 1):
            candidate = tuple(word[start:stop])
            occurs_before = False
            for earlier in range(start):
                if earlier + len(candidate) <= len(word) and tuple(
                        word[earlier:earlier + len(candidate)]) == candidate:
                    occurs_before = True
                    break
            if not occurs_before:
                chosen = stop
                break
        factors.append((start, chosen))
        start = chosen
    return factors


def _contexts(word: Sequence[int], factors: Sequence[tuple[int, int]], budget: int):
    width = budget + 2
    number = (len(factors) + width - 1) // width
    for block in range(number - 1):
        first = block * width
        second_end = min(len(factors), first + 2 * width)
        first_end = min(len(factors), first + width)
        head = factors[first_end - 1][1] - 1
        following_head = factors[second_end - 1][1] - 1
        start = factors[first][0]
        end = factors[second_end - 1][1]
        suffix = end - start
        yield max(0, start - suffix), end, head, following_head


def _count_errors(word: Sequence[int], start: int, end: int, period: int) -> int:
    return sum(word[i] != word[i + period] for i in range(start, end - period + 1))


def _maximal_in_context(word: Sequence[int], lo: int, hi: int, start: int,
                        end: int, period: int, budget: int, errors: int) -> bool:
    if start > lo and errors + int(word[start - 1] != word[start - 1 + period]) <= budget:
        return False
    if end + 1 < hi and errors + int(word[end + 1 - period] != word[end + 1]) <= budget:
        return False
    return True


def _direct_records(word: Sequence[int], budget: int):
    factors = _factor_by_first_novel_prefix(word)
    found: set[tuple[int, int, int, int]] = set()
    for lo, hi, head, next_head in _contexts(word, factors, budget):
        local_head = head - lo
        local_next = next_head - lo
        part = word[lo:hi]
        for start in range(len(part)):
            for end in range(start + 1, len(part)):
                for period in range(1, (end - start + 1) // 2 + 1):
                    errors = _count_errors(part, start, end, period)
                    if errors > budget:
                        continue
                    if start > local_head + 1 or end < local_head - 1:
                        continue
                    if start <= local_next + 1 and end >= local_next - 1:
                        continue
                    if not _maximal_in_context(part, 0, len(part), start, end,
                                               period, budget, errors):
                        continue
                    found.add((lo + start, end - start + 1, period, errors))
    return sorted(found, key=lambda item: (item[0], item[1], item[2], item[3]))


def _payload(word: Sequence[int], budget: int) -> bytes:
    records = _direct_records(word, budget)
    payload = bytearray(len(records).to_bytes(8, "little", signed=True))
    for record in records:
        for field in record:
            payload.extend(field.to_bytes(8, "little", signed=True))
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
    parsed = _frame(values, input_length)
    if parsed is None:
        return -1, b""
    word, budget = parsed
    payload = _payload(word, budget)
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
