"""Iterative, target-weighted verifier for hierarchical radiosity links."""

from collections.abc import Sequence
from math import isfinite

MAX_DEPTH = 5
MAX_INPUT_LENGTH = 11


def expected_output(values: Sequence[float] | None) -> tuple[int, tuple[float, ...]]:
    if (values is None or not isinstance(values, (list, tuple))
            or len(values) != MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not isfinite(value)
                   for value in values)):
        return -1, ()
    tx, ty, target_side, sx, sy, source_side, gap, brightness, reflectance, bound, depth_value = map(float, values)
    if (not (-8 <= tx <= 8 and -8 <= ty <= 8 and -8 <= sx <= 8 and -8 <= sy <= 8)
            or target_side not in (1, 2, 4) or source_side not in (1, 2, 4)
            or not (1 <= gap <= 8 and target_side <= gap and source_side <= gap)
            or not (0 <= brightness <= 4 and 0 <= reflectance <= 1)
            or not (0 <= bound <= 1 and depth_value == int(depth_value)
                    and 0 <= depth_value <= MAX_DEPTH)):
        return -1, ()

    stack = [(tx, ty, target_side, sx, sy, source_side, 0, 1.0)]
    total = 0.0
    leaf_count = 0
    max_leaf_depth = 0
    while stack:
        target_x, target_y, tside, source_x, source_y, sside, level, weight = stack.pop()
        source_area = sside * sside
        distance_squared = ((source_x - target_x) ** 2
                            + (source_y - target_y) ** 2 + gap * gap)
        parent = source_area * gap * gap / (distance_squared * distance_squared)
        split_source = sside >= tside
        child_side = (sside if split_source else tside) * 0.5
        offset = child_side * 0.5
        probe = 0.0
        child_nodes = []
        for dx, dy in ((-offset, -offset), (offset, -offset),
                       (-offset, offset), (offset, offset)):
            if split_source:
                cx, cy, cs = source_x + dx, source_y + dy, child_side
                child_area = cs * cs
                child_distance = ((cx - target_x) ** 2 + (cy - target_y) ** 2
                                  + gap * gap)
                child_factor = child_area * gap * gap / (child_distance * child_distance)
                child_nodes.append((target_x, target_y, tside, cx, cy, cs,
                                    level + 1, weight))
                probe += child_factor
            else:
                cx, cy, cs = target_x + dx, target_y + dy, child_side
                child_distance = ((source_x - cx) ** 2 + (source_y - cy) ** 2
                                  + gap * gap)
                child_factor = source_area * gap * gap / (child_distance * child_distance)
                child_nodes.append((cx, cy, cs, source_x, source_y, sside,
                                    level + 1, weight * 0.25))
                probe += child_factor * 0.25
        if level >= int(depth_value) or abs(probe - parent) <= bound:
            total += weight * parent
            leaf_count += 1
            max_leaf_depth = max(max_leaf_depth, level)
        else:
            stack.extend(child_nodes)

    return 3, (reflectance * brightness * total,
               float(leaf_count), float(max_leaf_depth))
