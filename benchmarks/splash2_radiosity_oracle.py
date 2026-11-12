"""Recursive reference for a bounded hierarchical radiosity link profile."""

from collections.abc import Sequence
from math import isfinite

MAX_INPUT_LENGTH = 11
MAX_PARSEABLE_INPUT_LENGTH = 12
MAX_OUTPUT_ELEMENTS = 3
MAX_DEPTH = 5
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _parse(values: Sequence[float] | None,
           input_length: int | None) -> tuple[float, ...] | None:
    if (values is None or not isinstance(values, (list, tuple))
            or len(values) != MAX_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    if any(type(value) not in (int, float) or not isfinite(value) for value in values):
        return None
    tx, ty, target_side, sx, sy, source_side, gap, brightness, reflectance, bound, depth = map(float, values)
    if (not -8 <= tx <= 8 or not -8 <= ty <= 8
            or not -8 <= sx <= 8 or not -8 <= sy <= 8
            or target_side not in (1, 2, 4) or source_side not in (1, 2, 4)
            or not 1 <= gap <= 8 or target_side > gap or source_side > gap
            or not 0 <= brightness <= 4 or not 0 <= reflectance <= 1
            or not 0 <= bound <= 1 or depth != int(depth)
            or not 0 <= depth <= MAX_DEPTH):
        return None
    return (tx, ty, target_side, sx, sy, source_side, gap,
            brightness, reflectance, bound, depth)


def _factor(tx: float, ty: float, source_area: float,
            sx: float, sy: float, gap: float) -> float:
    """Return pi times the centroid-sampled diffuse form factor."""
    distance_squared = (sx - tx) ** 2 + (sy - ty) ** 2 + gap ** 2
    return source_area * gap ** 2 / (distance_squared ** 2)


def _children(x: float, y: float, side: float):
    child_side = side * 0.5
    offset = side * 0.25
    for dx, dy in ((-offset, -offset), (offset, -offset),
                   (-offset, offset), (offset, offset)):
        yield x + dx, y + dy, child_side


def evaluate(values: Sequence[float] | None,
             input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    """Build one adaptive patch-pair hierarchy and gather its transfer."""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, ()
    tx, ty, target_side, sx, sy, source_side, gap, brightness, reflectance, bound, max_depth = parsed
    leaves = 0
    deepest = 0
    transfer = 0.0

    def visit(target_x: float, target_y: float, current_target_side: float,
              source_x: float, source_y: float, current_source_side: float,
              depth: int, weight: float) -> None:
        nonlocal leaves, deepest, transfer
        source_area = current_source_side ** 2
        coarse = _factor(target_x, target_y, source_area,
                         source_x, source_y, gap)
        split_source = current_source_side >= current_target_side
        fine = 0.0
        if split_source:
            for child_x, child_y, child_side in _children(
                    source_x, source_y, current_source_side):
                fine += _factor(target_x, target_y, child_side ** 2,
                                child_x, child_y, gap)
        else:
            for child_x, child_y, child_side in _children(
                    target_x, target_y, current_target_side):
                fine += 0.25 * _factor(child_x, child_y, source_area,
                                       source_x, source_y, gap)
        if depth >= max_depth or abs(fine - coarse) <= bound:
            transfer += weight * coarse
            leaves += 1
            deepest = max(deepest, depth)
            return
        if split_source:
            for child_x, child_y, child_side in _children(
                    source_x, source_y, current_source_side):
                visit(target_x, target_y, current_target_side,
                      child_x, child_y, child_side, depth + 1, weight)
        else:
            for child_x, child_y, child_side in _children(
                    target_x, target_y, current_target_side):
                visit(child_x, child_y, child_side,
                      source_x, source_y, current_source_side,
                      depth + 1, weight * 0.25)

    visit(tx, ty, target_side, sx, sy, source_side, 0, 1.0)
    return MAX_OUTPUT_ELEMENTS, (reflectance * brightness * transfer,
                                 float(leaves), float(deepest))


def expected_output(values: Sequence[float] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and
                (type(capacity) is not int or capacity < 0)
            or input_length is not None and
                (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, ()
    if input_is_null:
        return -1, ()
    result, output = evaluate(values, input_length)
    if result < 0:
        return result, output
    if output_is_null or capacity is not None and capacity < result:
        return -2, ()
    return result, output
