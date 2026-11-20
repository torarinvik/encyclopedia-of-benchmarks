"""Source-shaped arbitrary-arrival interval updates for a bottom-k ADS."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_N = 32
MIN_K = 2
MAX_K = 4
MAX_VALID_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
MAX_OUTPUT_WORDS = 1 + 3 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS
WORKSPACE_BYTES = 4096
DISTANCE_LIMIT = 1_000_000
END_SENTINEL = DISTANCE_LIMIT + 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool):
    if input_is_null or values is None:
        return None
    try:
        size = len(values)
    except TypeError:
        return None
    if input_length is not None and (type(input_length) is not int
                                      or input_length != size):
        return None
    if not 2 <= size <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63)
           for word in values):
        return None
    n, k = values[0], values[1]
    if not 2 <= k <= MAX_K or not k <= n <= MAX_N:
        return None
    if size != 2 + 3 * n:
        return None

    records: list[tuple[int, int, int]] = []
    seen_ids = [False] * n
    seen_ranks = [False] * n
    seen_distances: set[int] = set()
    for offset in range(n):
        item, distance, rank = values[2 + 3 * offset:5 + 3 * offset]
        if (not 0 <= item < n or seen_ids[item]
                or not 0 <= rank < n or seen_ranks[rank]
                or not 0 <= distance <= DISTANCE_LIMIT
                or distance in seen_distances):
            return None
        seen_ids[item] = True
        seen_ranks[rank] = True
        seen_distances.add(distance)
        records.append((item, distance, rank))

    seed_distances = [record[1] for record in records[:k]]
    if any(seed_distances[i - 1] >= seed_distances[i] for i in range(1, k)):
        return None
    if any(record[1] <= seed_distances[-1] for record in records[k:]):
        return None
    return n, k, records


def _intervals(records: list[tuple[int, int, int]], k: int):
    # Mutable records are [item ID, rank, start, end]. The first k items are
    # the complete initial nearest set, so each begins an interval to sentinel.
    intervals: list[list[int]] = [
        [item, rank, distance, END_SENTINEL]
        for item, distance, rank in records[:k]
    ]
    for item, distance, rank in records[k:]:
        active = [entry for entry in intervals
                  if entry[2] <= distance < entry[3]]
        if len(active) != k:
            return None
        worst = max(active, key=lambda entry: entry[1])
        if rank >= worst[1]:
            continue

        # The former maximum-rank interval ends at its old right boundary.
        # The new item replaces it until the next boundary where the same
        # replacement rule must be checked again.
        cursor = worst[3]
        worst[3] = distance
        while cursor < END_SENTINEL:
            at_boundary = [entry for entry in intervals
                           if entry[2] <= cursor < entry[3]]
            if not at_boundary:
                break
            next_worst = max(at_boundary, key=lambda entry: entry[1])
            if next_worst[1] <= rank:
                break
            next_end = next_worst[3]
            next_worst[3] = cursor
            cursor = next_end
        intervals.append([item, rank, distance, cursor])

    result = [(entry[0], entry[2], entry[3]) for entry in intervals
              if entry[2] < entry[3]]
    result.sort(key=lambda interval: (interval[1], interval[0]))
    return result


def evaluate(values: Sequence[int] | None, input_length: int | None = None,
             input_is_null: bool = False) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    _n, k, records = parsed
    intervals = _intervals(records, k)
    if intervals is None:
        return INVALID_RESULT, b""
    words = [len(intervals)]
    for item, start, end in intervals:
        words.extend((item, start, end))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if len(payload) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    return len(payload), payload


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    result, payload = evaluate(values, input_length, input_is_null)
    if result < 0:
        return result, payload
    if output_is_null or (output_capacity is not None
                          and output_capacity < result):
        return OUTPUT_ERROR, b""
    return result, payload
