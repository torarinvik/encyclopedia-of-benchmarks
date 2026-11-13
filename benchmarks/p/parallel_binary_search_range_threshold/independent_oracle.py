"""Independent per-query event replay and direct range-scan oracle."""

from __future__ import annotations

MAX_N = 16
MAX_EVENTS = 32
MAX_QUERIES = 32
MAX_THRESHOLD = 512_000
MAX_VALID_INPUT_LENGTH = 195
MAX_PARSEABLE_INPUT_LENGTH = 196
WORKSPACE_BYTES = 4096


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (tuple, list)):
        return None
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, event_count, query_count = values[:3]
    if (not 1 <= n <= MAX_N or not 0 <= event_count <= MAX_EVENTS
            or not 0 <= query_count <= MAX_QUERIES
            or len(values) != 3 + 3 * event_count + 3 * query_count):
        return None
    cursor = 3
    events = []
    for _ in range(event_count):
        left, right, delta = values[cursor:cursor + 3]
        cursor += 3
        if not 0 <= left <= right < n or not 0 <= delta <= 1000:
            return None
        events.append((left, right, delta))
    queries = []
    for _ in range(query_count):
        left, right, target = values[cursor:cursor + 3]
        cursor += 3
        if not 0 <= left <= right < n or not 1 <= target <= MAX_THRESHOLD:
            return None
        queries.append((left, right, target))
    return n, events, queries


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return -1
    n, events, queries = parsed
    checksum = 0
    for query_id, (left, right, target) in enumerate(queries):
        current = [0] * n
        answer = len(events) + 1
        if sum(current[left:right + 1]) >= target:
            answer = 0
        else:
            for time, (event_left, event_right, delta) in enumerate(events, 1):
                for position in range(event_left, event_right + 1):
                    current[position] += delta
                if sum(current[left:right + 1]) >= target:
                    answer = time
                    break
        checksum += (query_id + 1) * (answer + 1)
    return checksum
