"""Direct aligned-block scan reference for the bounded HsaDelta profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (
    COPY,
    INSERT,
    INVALID_RESULT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_REFERENCE_LENGTH,
    MAX_VERSION_LENGTH,
    MIN_BLOCK_SIZE,
    MAX_BLOCK_SIZE,
    OUTPUT_ERROR,
)


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
    return (tuple(payload[:reference_length]),
            tuple(payload[reference_length:]), block_size)


def _common_prefix(reference: Sequence[int], version: Sequence[int],
                   source: int, target: int) -> tuple[int, int, int]:
    length = 0
    while (source + length < len(reference) and target + length < len(version)
           and reference[source + length] == version[target + length]):
        length += 1
    return source, target, length


def _find_at(reference: Sequence[int], version: Sequence[int], block_size: int,
             target: int, target_floor: int) -> tuple[int, int, int] | None:
    query_blocks = (len(version) - target) // block_size
    if query_blocks == 0:
        return None
    depths: list[tuple[int, int]] = []
    maximum_depth = 0
    for source in range(0, len(reference) - block_size + 1, block_size):
        if tuple(reference[source:source + block_size]) != tuple(version[target:target + block_size]):
            continue
        depth = 0
        while (depth < query_blocks
               and source + (depth + 1) * block_size <= len(reference)
               and target + (depth + 1) * block_size <= len(version)
               and tuple(reference[source + depth * block_size:
                                   source + (depth + 1) * block_size])
               == tuple(version[target + depth * block_size:
                                target + (depth + 1) * block_size])):
            depth += 1
        depths.append((source, depth))
        maximum_depth = max(maximum_depth, depth)
    if maximum_depth == 0:
        return None
    required_depth = max(1, maximum_depth - 1)
    best: tuple[int, int, int] | None = None
    for source, depth in depths:
        if depth < required_depth:
            continue
        start_source, start_target, length = _common_prefix(
            reference, version, source, target)
        if length < block_size:
            continue
        while (start_source > 0 and start_target > target_floor
               and reference[start_source - 1] == version[start_target - 1]):
            start_source -= 1
            start_target -= 1
            length += 1
        candidate = (start_source, start_target, length)
        if (best is None or length > best[2]
                or (length == best[2] and (start_target, start_source)
                    < (best[1], best[0]))):
            best = candidate
    return best


def _tokens(reference: Sequence[int], version: Sequence[int],
            block_size: int) -> list[int]:
    result: list[int] = []
    cursor = 0
    consumed = 0
    while cursor + block_size <= len(version):
        best: tuple[int, int, int] | None = None
        scan_end = min(cursor + block_size - 1, len(version) - block_size)
        for target in range(cursor, scan_end + 1):
            candidate = _find_at(reference, version, block_size, target, consumed)
            if candidate is not None and (best is None or candidate[2] > best[2]
                    or (candidate[2] == best[2]
                        and (candidate[1], candidate[0]) < (best[1], best[0]))):
                best = candidate
        if best is None:
            cursor += 1
            continue
        source, target, length = best
        if target > consumed:
            inserted = version[consumed:target]
            result.extend((INSERT, len(inserted), *inserted))
        result.extend((COPY, source, length))
        consumed = target + length
        cursor = consumed
    if consumed < len(version):
        inserted = version[consumed:]
        result.extend((INSERT, len(inserted), *inserted))
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    reference, version, block_size = parsed
    payload = b"".join(struct.pack("<q", word)
                       for word in _tokens(reference, version, block_size))
    if payload and (output_is_null or capacity is not None
                    and (type(capacity) is not int or capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
