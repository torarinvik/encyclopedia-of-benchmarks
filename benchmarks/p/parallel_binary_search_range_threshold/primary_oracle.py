"""Batched parallel-binary-search oracle for first threshold-crossing times."""

from __future__ import annotations

MAX_N = 16
MAX_EVENTS = 32
MAX_QUERIES = 32
MAX_DELTA = 1000
MAX_THRESHOLD = 512_000
MAX_VALID_INPUT_LENGTH = 195
MAX_PARSEABLE_INPUT_LENGTH = 196
WORKSPACE_BYTES = 4096


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, event_count, query_count = values[:3]
    if not 1 <= n <= MAX_N or not 0 <= event_count <= MAX_EVENTS or not 0 <= query_count <= MAX_QUERIES:
        return None
    if len(values) != 3 + 3 * event_count + 3 * query_count:
        return None

    cursor = 3
    events: list[tuple[int, int, int]] = []
    for _ in range(event_count):
        left, right, delta = values[cursor:cursor + 3]
        cursor += 3
        if not 0 <= left <= right < n or not 0 <= delta <= MAX_DELTA:
            return None
        events.append((left, right, delta))

    queries: list[tuple[int, int, int]] = []
    for _ in range(query_count):
        left, right, target = values[cursor:cursor + 3]
        cursor += 3
        if not 0 <= left <= right < n or not 1 <= target <= MAX_THRESHOLD:
            return None
        queries.append((left, right, target))
    return n, events, queries


def _bit_add(bit: list[int], index: int, delta: int, limit: int) -> None:
    while index <= limit + 1:
        bit[index] += delta
        index += index & -index


def _bit_sum(bit: list[int], index: int) -> int:
    total = 0
    while index > 0:
        total += bit[index]
        index -= index & -index
    return total


def _range_add(bit1: list[int], bit2: list[int], n: int,
               left: int, right: int, delta: int) -> None:
    lo = left + 1
    hi = right + 1
    _bit_add(bit1, lo, delta, n)
    _bit_add(bit1, hi + 1, -delta, n)
    _bit_add(bit2, lo, delta * (lo - 1), n)
    _bit_add(bit2, hi + 1, -delta * hi, n)


def _prefix_sum(bit1: list[int], bit2: list[int], count: int) -> int:
    return count * _bit_sum(bit1, count) - _bit_sum(bit2, count)


def _range_sum(bit1: list[int], bit2: list[int], left: int, right: int) -> int:
    return (_prefix_sum(bit1, bit2, right + 1)
            - _prefix_sum(bit1, bit2, left))


def expected_result(values, input_is_null=False, input_length=None):
    """Return weighted earliest-time answers, or -1 for malformed input."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return -1
    n, events, queries = parsed
    event_count = len(events)
    query_count = len(queries)

    low = [0] * query_count
    high = [event_count + 1] * query_count
    active = True
    while active:
        heads = [-1] * (MAX_EVENTS + 1)
        next_query = [-1] * query_count
        active = False
        for query_id in range(query_count):
            if high[query_id] - low[query_id] > 1:
                active = True
                middle = (low[query_id] + high[query_id]) // 2
                next_query[query_id] = heads[middle]
                heads[middle] = query_id
        if not active:
            break

        bit1 = [0] * (MAX_N + 2)
        bit2 = [0] * (MAX_N + 2)
        applied = 0
        for middle in range(event_count + 1):
            while applied < middle:
                left, right, delta = events[applied]
                _range_add(bit1, bit2, n, left, right, delta)
                applied += 1
            query_id = heads[middle]
            while query_id != -1:
                left, right, target = queries[query_id]
                if _range_sum(bit1, bit2, left, right) >= target:
                    high[query_id] = middle
                else:
                    low[query_id] = middle
                query_id = next_query[query_id]

    return sum((query_id + 1) * (high[query_id] + 1)
               for query_id in range(query_count))
