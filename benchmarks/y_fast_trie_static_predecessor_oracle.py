"""Static y-fast trie oracle for batched predecessor and successor queries."""

from __future__ import annotations

from collections.abc import Sequence

MAX_KEYS = 256
MAX_QUERIES = 256
UNIVERSE_BITS = 16
BUCKET_SIZE = 16
MAX_VALID_INPUT_LENGTH = 2 + MAX_KEYS + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 2
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or actual_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    key_count, query_count = values[0], values[1]
    if not 0 <= key_count <= MAX_KEYS or not 0 <= query_count <= MAX_QUERIES:
        return None
    if actual_length != 2 + key_count + query_count:
        return None
    keys = list(values[2:2 + key_count])
    queries = list(values[2 + key_count:])
    if any(not 0 <= key < (1 << UNIVERSE_BITS) for key in keys + queries):
        return None
    if len(set(keys)) != len(keys):
        return None
    keys.sort()
    return keys, queries


def _build_separator_trie(separators: list[int]) -> tuple[list[list[int]], list[int], list[int]]:
    """Build a compact binary prefix trie with each subtree's first separator rank."""
    children: list[list[int]] = [[-1, -1]]
    minimum_rank = [MAX_KEYS]
    leaf_rank = [-1]
    for rank, separator in enumerate(separators):
        node = 0
        minimum_rank[node] = min(minimum_rank[node], rank)
        for depth in range(UNIVERSE_BITS - 1, -1, -1):
            bit = (separator >> depth) & 1
            child = children[node][bit]
            if child < 0:
                child = len(children)
                children[node][bit] = child
                children.append([-1, -1])
                minimum_rank.append(MAX_KEYS)
                leaf_rank.append(-1)
            node = child
            minimum_rank[node] = min(minimum_rank[node], rank)
        leaf_rank[node] = rank
    return children, minimum_rank, leaf_rank


def _lower_bound_separator(separators: list[int], children: list[list[int]],
                            minimum_rank: list[int], leaf_rank: list[int],
                            query: int) -> int:
    if not separators:
        return -1
    node = 0
    candidate = -1
    for depth in range(UNIVERSE_BITS - 1, -1, -1):
        bit = (query >> depth) & 1
        if bit == 0:
            right = children[node][1]
            if right >= 0 and (candidate < 0 or minimum_rank[right] < candidate):
                candidate = minimum_rank[right]
        child = children[node][bit]
        if child < 0:
            return candidate
        node = child
    exact = leaf_rank[node]
    return exact if exact >= 0 else candidate


def _build_index(keys: list[int]) -> tuple[list[list[int]], list[int], tuple[list[list[int]], list[int], list[int]]]:
    buckets = [keys[start:start + BUCKET_SIZE]
               for start in range(0, len(keys), BUCKET_SIZE)]
    separators = [bucket[-1] for bucket in buckets]
    trie = _build_separator_trie(separators)
    return buckets, separators, trie


def _strict_neighbors(buckets: list[list[int]], separators: list[int],
                      trie: tuple[list[list[int]], list[int], list[int]],
                      query: int) -> tuple[int, int]:
    if not buckets:
        return -1, -1
    bucket_rank = _lower_bound_separator(separators, *trie, query)
    if bucket_rank < 0:
        bucket_rank = len(buckets) - 1
    bucket = buckets[bucket_rank]

    low, high = 0, len(bucket)
    while low < high:
        middle = (low + high) // 2
        if bucket[middle] < query:
            low = middle + 1
        else:
            high = middle
    predecessor = bucket[low - 1] if low else (
        buckets[bucket_rank - 1][-1] if bucket_rank else -1)

    low, high = 0, len(bucket)
    while low < high:
        middle = (low + high) // 2
        if bucket[middle] <= query:
            low = middle + 1
        else:
            high = middle
    successor = bucket[low] if low < len(bucket) else (
        buckets[bucket_rank + 1][0] if bucket_rank + 1 < len(buckets) else -1)
    return predecessor, successor


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    keys, queries = parsed
    buckets, separators, trie = _build_index(keys)
    checksum = 0
    for index, query in enumerate(queries, start=1):
        predecessor, successor = _strict_neighbors(buckets, separators, trie, query)
        checksum += index * (
            (predecessor + 1) + ((1 << UNIVERSE_BITS) + 1) * (successor + 1))
    return checksum
