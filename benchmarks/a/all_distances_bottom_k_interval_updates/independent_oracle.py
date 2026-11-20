"""Definition-based reference that recomputes every distance-prefix bottom-k."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_N = 32
MAX_K = 4
MAX_VALID_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
MAX_OUTPUT_BYTES = 776
DISTANCE_LIMIT = 1_000_000
END_SENTINEL = DISTANCE_LIMIT + 1


def _read(values: Sequence[int] | None, input_length: int | None,
          input_is_null: bool):
    if input_is_null or values is None:
        return None
    try:
        length = len(values)
    except TypeError:
        return None
    if input_length is not None and (type(input_length) is not int
                                      or input_length != length):
        return None
    if not 2 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    for value in values:
        if type(value) is not int or not -(1 << 63) <= value < (1 << 63):
            return None
    n, k = values[0], values[1]
    if not 2 <= k <= MAX_K or not k <= n <= MAX_N:
        return None
    if length != 2 + 3 * n:
        return None
    records = []
    for i in range(n):
        records.append(tuple(values[2 + 3 * i:5 + 3 * i]))
    ids = [record[0] for record in records]
    ranks = [record[2] for record in records]
    distances = [record[1] for record in records]
    if set(ids) != set(range(n)) or set(ranks) != set(range(n)):
        return None
    if (any(not 0 <= d <= DISTANCE_LIMIT for d in distances)
            or len(set(distances)) != n):
        return None
    seed_distances = distances[:k]
    if (any(seed_distances[i - 1] >= seed_distances[i] for i in range(1, k))
            or any(d <= seed_distances[-1] for d in distances[k:])):
        return None
    return n, k, records


def evaluate(values: Sequence[int] | None, input_length: int | None = None,
             input_is_null: bool = False) -> tuple[int, bytes]:
    parsed = _read(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, k, records = parsed
    by_distance = sorted(records, key=lambda record: record[1])
    output_intervals = []
    for item, distance, rank in records:
        top_at_start = sorted(
            (candidate for candidate in by_distance if candidate[1] <= distance),
            key=lambda candidate: candidate[2])[:k]
        if item not in {candidate[0] for candidate in top_at_start}:
            continue
        end = END_SENTINEL
        for threshold in (candidate[1] for candidate in by_distance
                          if candidate[1] > distance):
            eligible = [candidate for candidate in by_distance
                        if candidate[1] <= threshold]
            top = sorted(eligible, key=lambda candidate: candidate[2])[:k]
            if item not in {candidate[0] for candidate in top}:
                end = threshold
                break
        output_intervals.append((item, distance, end))
    output_intervals.sort(key=lambda interval: (interval[1], interval[0]))
    words = [len(output_intervals)]
    for interval in output_intervals:
        words.extend(interval)
    payload = b"".join(struct.pack("<q", word) for word in words)
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
        return -1, b""
    result, payload = evaluate(values, input_length, input_is_null)
    if result < 0:
        return result, payload
    if output_is_null or (output_capacity is not None
                          and output_capacity < result):
        return -2, b""
    return result, payload
