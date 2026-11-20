"""Bounded fixed-block HsaDelta profile using suffix-array match lookup."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_REFERENCE_LENGTH = 32
MAX_VERSION_LENGTH = 32
MIN_BLOCK_SIZE = 2
MAX_BLOCK_SIZE = 4
MAX_BLOCKS = MAX_REFERENCE_LENGTH // MIN_BLOCK_SIZE
MAX_VALID_INPUT_LENGTH = 3 + MAX_REFERENCE_LENGTH + MAX_VERSION_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 3 * (MAX_VERSION_LENGTH // MIN_BLOCK_SIZE) \
    + 2 * (MAX_VERSION_LENGTH // MIN_BLOCK_SIZE + 1) + MAX_VERSION_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS
MAX_WORKSPACE_BYTES = 2048
INVALID_RESULT = -1
OUTPUT_ERROR = -2
INSERT = 0
COPY = 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, ...], tuple[int, ...], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    reference_length, version_length, block_size = values[:3]
    if (not 0 <= reference_length <= MAX_REFERENCE_LENGTH
            or not 0 <= version_length <= MAX_VERSION_LENGTH
            or not MIN_BLOCK_SIZE <= block_size <= MAX_BLOCK_SIZE
            or len(values) != 3 + reference_length + version_length):
        return None
    payload = values[3:]
    if any(not 0 <= value <= 255 for value in payload):
        return None
    reference = tuple(payload[:reference_length])
    version = tuple(payload[reference_length:])
    return reference, version, block_size


def _block_hash(data: Sequence[int], start: int, width: int) -> int:
    value = 0
    for offset in range(width):
        value = value * 257 + data[start + offset] + 1
    return value


def _prefix_compare(reference_hashes: Sequence[int], suffix_start: int,
                    query_hashes: Sequence[int], prefix_length: int) -> int:
    for offset in range(prefix_length):
        if suffix_start + offset >= len(reference_hashes):
            return -1
        left = reference_hashes[suffix_start + offset]
        right = query_hashes[offset]
        if left != right:
            return -1 if left < right else 1
    return 0


def _prefix_interval(suffix_array: Sequence[int], reference_hashes: Sequence[int],
                     query_hashes: Sequence[int], prefix_length: int) -> tuple[int, int]:
    low, high = 0, len(suffix_array)
    while low < high:
        middle = (low + high) // 2
        if _prefix_compare(reference_hashes, suffix_array[middle],
                           query_hashes, prefix_length) < 0:
            low = middle + 1
        else:
            high = middle
    first = low
    high = len(suffix_array)
    while low < high:
        middle = (low + high) // 2
        if _prefix_compare(reference_hashes, suffix_array[middle],
                           query_hashes, prefix_length) <= 0:
            low = middle + 1
        else:
            high = middle
    return first, low


def _best_depth(suffix_array: Sequence[int], reference_hashes: Sequence[int],
                query_hashes: Sequence[int]) -> int:
    low, high = 0, min(len(reference_hashes), len(query_hashes)) + 1
    while low + 1 < high:
        middle = (low + high) // 2
        first, last = _prefix_interval(suffix_array, reference_hashes,
                                       query_hashes, middle)
        if first < last:
            low = middle
        else:
            high = middle
    return low


def _extend(reference: Sequence[int], version: Sequence[int],
            source: int, target: int, target_floor: int) -> tuple[int, int, int]:
    length = 0
    while (source + length < len(reference) and target + length < len(version)
           and reference[source + length] == version[target + length]):
        length += 1
    start_source, start_target = source, target
    while (start_source > 0 and start_target > target_floor
           and reference[start_source - 1] == version[start_target - 1]):
        start_source -= 1
        start_target -= 1
        length += 1
    return start_source, start_target, length


def _find_at(reference: Sequence[int], version: Sequence[int], block_size: int,
             suffix_array: Sequence[int], reference_hashes: Sequence[int],
             target: int, target_floor: int) -> tuple[int, int, int] | None:
    query_count = (len(version) - target) // block_size
    if query_count == 0 or not reference_hashes:
        return None
    query_hashes = tuple(_block_hash(version, target + index * block_size, block_size)
                         for index in range(query_count))
    depth = _best_depth(suffix_array, reference_hashes, query_hashes)
    if depth == 0:
        return None
    # The source's bounded in-memory refinement checks the maximum hash depth
    # and the immediately shorter depth before extending exact bytes.
    checked_depth = max(1, depth - 1)
    first, last = _prefix_interval(suffix_array, reference_hashes,
                                   query_hashes, checked_depth)
    best: tuple[int, int, int] | None = None
    for suffix_rank in range(first, last):
        source = suffix_array[suffix_rank] * block_size
        if source + block_size > len(reference):
            continue
        start_source, start_target, length = _extend(
            reference, version, source, target, target_floor)
        if length < block_size:
            continue
        candidate = (start_source, start_target, length)
        if (best is None or length > best[2]
                or (length == best[2] and (start_target, start_source)
                    < (best[1], best[0]))):
            best = candidate
    return best


def _delta_tokens(reference: Sequence[int], version: Sequence[int],
                  block_size: int) -> list[int]:
    reference_hashes = tuple(
        _block_hash(reference, start, block_size)
        for start in range(0, len(reference) - block_size + 1, block_size)
    )
    suffix_array = sorted(range(len(reference_hashes)),
                          key=lambda start: (reference_hashes[start:], start))
    tokens: list[int] = []
    cursor = 0
    consumed = 0
    while cursor + block_size <= len(version):
        best: tuple[int, int, int] | None = None
        scan_end = min(cursor + block_size - 1, len(version) - block_size)
        for target in range(cursor, scan_end + 1):
            candidate = _find_at(reference, version, block_size, suffix_array,
                                 reference_hashes, target, consumed)
            if candidate is None:
                continue
            if (best is None or candidate[2] > best[2]
                    or (candidate[2] == best[2]
                        and (candidate[1], candidate[0]) < (best[1], best[0]))):
                best = candidate
        if best is None:
            cursor += 1
            continue
        source, target, length = best
        if target > consumed:
            inserted = version[consumed:target]
            tokens.extend((INSERT, len(inserted), *inserted))
        tokens.extend((COPY, source, length))
        consumed = target + length
        cursor = consumed
    if consumed < len(version):
        inserted = version[consumed:]
        tokens.extend((INSERT, len(inserted), *inserted))
    return tokens


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool):
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    reference, version, block_size = parsed
    tokens = _delta_tokens(reference, version, block_size)
    payload = b"".join(struct.pack("<q", word) for word in tokens)
    if payload and (output_is_null or capacity is not None
                    and (type(capacity) is not int or capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
