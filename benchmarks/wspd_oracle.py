"""Independent bounded WSPD model and byte-output oracle."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_POINTS = 8
MAX_INPUT_LENGTH = 2 + 2 * MAX_POINTS
MAX_PAIRS = MAX_POINTS * (MAX_POINTS - 1) // 2
MAX_OUTPUT_BYTES = 8 + 16 * MAX_PAIRS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _pack_i64(value: int) -> bytes:
    return struct.pack("<q", value)


def _build_tree(points: list[tuple[int, int]], members: list[int]) -> dict:
    xs = [points[index][0] for index in members]
    ys = [points[index][1] for index in members]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    center_x = (min_x + max_x) / 2.0
    center_y = (min_y + max_y) / 2.0
    radius = math.hypot((max_x - min_x) / 2.0, (max_y - min_y) / 2.0)
    mask = sum(1 << index for index in members)
    node = {
        "members": members,
        "mask": mask,
        "center": (center_x, center_y),
        "radius": radius,
        "left": None,
        "right": None,
    }
    if len(members) == 1:
        return node

    axis = 0 if max_x - min_x >= max_y - min_y else 1
    ordered = sorted(members, key=lambda index: (points[index][axis], points[index][1 - axis], index))
    middle = len(ordered) // 2
    node["left"] = _build_tree(points, ordered[:middle])
    node["right"] = _build_tree(points, ordered[middle:])
    return node


def _well_separated(first: dict, second: dict, separation: int) -> bool:
    radius = max(first["radius"], second["radius"])
    dx = first["center"][0] - second["center"][0]
    dy = first["center"][1] - second["center"][1]
    distance = math.hypot(dx, dy)
    return distance - 2.0 * radius > separation * radius


def _decompose(root: dict, separation: int) -> list[tuple[int, int]]:
    pairs: list[tuple[int, int]] = []

    def cross(first: dict, second: dict) -> None:
        if _well_separated(first, second, separation):
            pairs.append((first["mask"], second["mask"]))
            return
        if first["radius"] > second["radius"]:
            cross(first["left"], second)
            cross(first["right"], second)
        else:
            cross(first, second["left"])
            cross(first, second["right"])

    def visit(node: dict) -> None:
        if node["left"] is None:
            return
        visit(node["left"])
        visit(node["right"])
        cross(node["left"], node["right"])

    visit(root)
    return pairs


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return pair count and masks serialized as little-endian signed 64-bit words."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or len(values) < 4):
        return INVALID_RESULT, b""
    count, separation = values[0], values[1]
    if not 1 <= count <= MAX_POINTS or not 1 <= separation <= 8 or len(values) != 2 + 2 * count:
        return INVALID_RESULT, b""
    points: list[tuple[int, int]] = []
    for index in range(count):
        x, y = values[2 + 2 * index], values[3 + 2 * index]
        if not -1000 <= x <= 1000 or not -1000 <= y <= 1000:
            return INVALID_RESULT, b""
        points.append((x, y))
    if len(set(points)) != count:
        return INVALID_RESULT, b""

    pairs = _decompose(_build_tree(points, list(range(count))), separation)
    if len(pairs) > MAX_PAIRS:
        return INVALID_RESULT, b""
    encoded = bytearray(_pack_i64(len(pairs)))
    for left_mask, right_mask in pairs:
        encoded += _pack_i64(left_mask)
        encoded += _pack_i64(right_mask)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), bytes(encoded)
