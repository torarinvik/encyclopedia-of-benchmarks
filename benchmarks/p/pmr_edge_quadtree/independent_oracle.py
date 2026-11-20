"""Top-down geometric reference using exact rational segment clipping."""
from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct

try:
    from .primary_oracle import (
        I64_MAX,
        I64_MIN,
        INVALID_RESULT,
        MAX_NODES,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_SEGMENTS,
        OUTPUT_ERROR,
        ROOT_BOUNDS,
        InvalidInput,
    )
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import (
        I64_MAX,
        I64_MIN,
        INVALID_RESULT,
        MAX_NODES,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_SEGMENTS,
        OUTPUT_ERROR,
        ROOT_BOUNDS,
        InvalidInput,
    )

MAX_DEPTH = 8


def _parse(values: Sequence[int]) -> tuple[list[tuple[int, int, int, int]], int]:
    if not isinstance(values, (list, tuple)):
        raise InvalidInput("input must be a list or tuple")
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("input length is outside the parseable range")
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        raise InvalidInput("input words must be signed 64-bit integers")
    count, threshold = values[:2]
    if not 0 <= count <= MAX_SEGMENTS or not 1 <= threshold <= MAX_SEGMENTS:
        raise InvalidInput("segment count or splitting threshold is out of range")
    if len(values) != 2 + 4 * count:
        raise InvalidInput("segment frame has the wrong exact length")
    segments = []
    for index in range(count):
        segment = tuple(values[2 + 4 * index: 6 + 4 * index])
        if any(not 0 <= coordinate <= 255 for coordinate in segment):
            raise InvalidInput("endpoint coordinate is out of range")
        if segment[0] == segment[2] and segment[1] == segment[3]:
            raise InvalidInput("zero-length segments are excluded")
        segments.append(segment)
    return segments, threshold


def _intersects_box(segment: tuple[int, int, int, int],
                    bounds: tuple[int, int, int, int]) -> bool:
    x0, y0, x1, y1 = (Fraction(2 * coordinate) for coordinate in segment)
    xmin, ymin, xmax, ymax = (Fraction(bound) for bound in bounds)
    enter = Fraction(0)
    leave = Fraction(1)
    for origin, delta, lower, upper in (
            (x0, x1 - x0, xmin, xmax), (y0, y1 - y0, ymin, ymax)):
        if delta == 0:
            if origin < lower or origin > upper:
                return False
            continue
        first = (lower - origin) / delta
        second = (upper - origin) / delta
        enter = max(enter, min(first, second))
        leave = min(leave, max(first, second))
        if enter > leave:
            return False
    return True


def _child_bounds(bounds: tuple[int, int, int, int]):
    xmin, ymin, xmax, ymax = bounds
    midx = (xmin + xmax) // 2
    midy = (ymin + ymax) // 2
    return (
        (xmin, midy, midx, ymax),
        (midx, midy, xmax, ymax),
        (xmin, ymin, midx, midy),
        (midx, ymin, xmax, midy),
    )


def _build_words(segments: list[tuple[int, int, int, int]], threshold: int) -> list[int]:
    records: list[tuple[int, int, int, list[int]]] = []

    def build(parent: int, quadrant: int, depth: int,
              bounds: tuple[int, int, int, int], ids: list[int]) -> int:
        if len(records) >= MAX_NODES:
            raise InvalidInput("bounded PMR tree exhausted its node allocation")
        node_id = len(records)
        records.append((parent, quadrant, depth, []))
        if len(ids) <= threshold:
            records[node_id] = (parent, quadrant, depth, ids)
            return node_id
        if depth >= MAX_DEPTH or len(records) + 4 > MAX_NODES:
            raise InvalidInput("bounded PMR tree cannot split this overfull cell")
        children = _child_bounds(bounds)
        for child_q, child_box in enumerate(children):
            child_ids = [sid for sid in ids if _intersects_box(segments[sid], child_box)]
            build(node_id, child_q, depth + 1, child_box, child_ids)
        return node_id

    all_ids = list(range(len(segments)))
    if any(not _intersects_box(segment, ROOT_BOUNDS) for segment in segments):
        raise InvalidInput("segment lies outside the root region")
    build(-1, -1, 0, ROOT_BOUNDS, all_ids)
    words = [len(records), len(segments)]
    for parent, quadrant, depth, ids in records:
        words.extend((parent, quadrant, depth, len(ids)))
        words.extend(ids)
    return words


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Rebuild the final split tree top-down using Fraction clipping predicates."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    try:
        segments, threshold = _parse(values)
        words = _build_words(segments, threshold)
    except InvalidInput:
        return INVALID_RESULT, b""
    encoded = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
