"""Independent oracle for a bounded clean-room median-cut palette builder."""

from __future__ import annotations

from typing import Sequence

BIN_SIDE = 32
MAX_PALETTE = 8
MAX_PIXELS = 16
MAX_INPUT_LENGTH = 50
MAX_OUTPUT_BYTES = 25


def _shrink(histogram: dict[tuple[int, int, int], int], box: dict[str, int]) -> None:
    points = [
        (r, g, b)
        for (r, g, b), weight in histogram.items()
        if weight and box["rmin"] <= r <= box["rmax"]
        and box["gmin"] <= g <= box["gmax"]
        and box["bmin"] <= b <= box["bmax"]
    ]
    box["rmin"] = min(r for r, _, _ in points)
    box["rmax"] = max(r for r, _, _ in points)
    box["gmin"] = min(g for _, g, _ in points)
    box["gmax"] = max(g for _, g, _ in points)
    box["bmin"] = min(b for _, _, b in points)
    box["bmax"] = max(b for _, _, b in points)


def _palette(pixels: Sequence[tuple[int, int, int]], palette_limit: int) -> list[tuple[int, int, int]]:
    histogram: dict[tuple[int, int, int], int] = {}
    for red, green, blue in pixels:
        key = (red >> 3, green >> 3, blue >> 3)
        histogram[key] = histogram.get(key, 0) + 1

    coordinates = tuple(zip(*(histogram.keys())))
    box = {
        "rmin": min(coordinates[0]), "rmax": max(coordinates[0]),
        "gmin": min(coordinates[1]), "gmax": max(coordinates[1]),
        "bmin": min(coordinates[2]), "bmax": max(coordinates[2]),
        "total": len(pixels),
    }
    boxes = [box]
    while len(boxes) < palette_limit:
        selected = -1
        largest_total = -1
        for index, candidate in enumerate(boxes):
            has_span = (
                candidate["rmax"] > candidate["rmin"]
                or candidate["gmax"] > candidate["gmin"]
                or candidate["bmax"] > candidate["bmin"]
            )
            if has_span and candidate["total"] > largest_total:
                selected = index
                largest_total = candidate["total"]
        if selected < 0:
            break

        upper = dict(boxes[selected])
        spans = (
            upper["rmax"] - upper["rmin"],
            upper["gmax"] - upper["gmin"],
            upper["bmax"] - upper["bmin"],
        )
        axis = 0 if spans[0] >= spans[1] and spans[0] >= spans[2] else (
            1 if spans[1] >= spans[2] else 2
        )
        low_key = ("rmin", "gmin", "bmin")[axis]
        high_key = ("rmax", "gmax", "bmax")[axis]
        first, last = upper[low_key], upper[high_key]
        along = [0] * BIN_SIDE
        for (red, green, blue), weight in histogram.items():
            if (upper["rmin"] <= red <= upper["rmax"]
                    and upper["gmin"] <= green <= upper["gmax"]
                    and upper["bmin"] <= blue <= upper["bmax"]):
                coordinate = (red, green, blue)[axis]
                along[coordinate] += weight
        split = first
        accumulated = 0
        median = upper["total"] // 2
        while split <= last:
            accumulated += along[split]
            if accumulated >= median:
                break
            split += 1
        if split == first:
            split += 1

        lower = dict(upper)
        lower[high_key] = split - 1
        upper[low_key] = split
        lower["total"] = sum(along[first:split])
        upper["total"] = sum(along[split:last + 1])
        _shrink(histogram, lower)
        _shrink(histogram, upper)
        boxes[selected] = upper
        boxes.insert(0, lower)

    return [
        ((item["rmin"] + item["rmax"]) * 4,
         (item["gmin"] + item["gmax"]) * 4,
         (item["bmin"] + item["bmax"]) * 4)
        for item in boxes
    ]


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))):
        return -1, b""
    if (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)):
        return -2, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 5
            or input_length > MAX_INPUT_LENGTH or input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return -1, b""
    palette_limit, pixel_count = values[:2]
    if not 1 <= palette_limit <= MAX_PALETTE or not 1 <= pixel_count <= MAX_PIXELS:
        return -1, b""
    if input_length != 2 + 3 * pixel_count:
        return -1, b""
    components = values[2:]
    if any(component < 0 or component > 255 for component in components):
        return -1, b""
    pixels = [tuple(components[i:i + 3]) for i in range(0, len(components), 3)]
    palette = _palette(pixels, palette_limit)
    output = bytes([len(palette), *(component for color in palette for component in color)])
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return -2, b""
    return len(output), output
