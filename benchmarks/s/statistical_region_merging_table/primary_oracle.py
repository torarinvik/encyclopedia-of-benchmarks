"""Ordered DSU reference for bounded supplied-bound region merging."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 74
MAX_OUTPUT_BYTES = 36
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    height, width = values[0], values[1]
    if not 1 <= height <= 6 or not 1 <= width <= 6:
        return None
    pixel_count = height * width
    if len(values) != 2 + 2 * pixel_count:
        return None
    thresholds = tuple(values[2:2 + pixel_count])
    intensities = tuple(values[2 + pixel_count:])
    if (any(not 0 <= bound <= 65535 for bound in thresholds)
            or any(not 0 <= pixel <= 255 for pixel in intensities)):
        return None
    return height, width, thresholds, intensities


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return `(result, output)` using sorted edges and union-by-size DSU."""
    if (type(output_is_null) is not bool
            or capacity is not None
            and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    height, width, thresholds, intensities = decoded
    count = height * width

    edges: list[tuple[int, int, int]] = []
    for position in range(count):
        if position % width + 1 < width:
            neighbor = position + 1
            edges.append((abs(intensities[position] - intensities[neighbor]),
                          position, neighbor))
        if position + width < count:
            neighbor = position + width
            edges.append((abs(intensities[position] - intensities[neighbor]),
                          position, neighbor))
    edges.sort()

    parents = list(range(count))
    sizes = [1] * count
    sums = list(intensities)
    smallest_position = list(range(count))

    def find(position: int) -> int:
        while parents[position] != position:
            parents[position] = parents[parents[position]]
            position = parents[position]
        return position

    for _, left_pixel, right_pixel in edges:
        left_root = find(left_pixel)
        right_root = find(right_pixel)
        if left_root == right_root:
            continue
        left_size, right_size = sizes[left_root], sizes[right_root]
        cross_delta = sums[left_root] * right_size - sums[right_root] * left_size
        allowed = thresholds[left_size - 1] + thresholds[right_size - 1]
        if cross_delta * cross_delta > allowed * left_size**2 * right_size**2:
            continue
        if left_size < right_size:
            left_root, right_root = right_root, left_root
        parents[right_root] = left_root
        sizes[left_root] += sizes[right_root]
        sums[left_root] += sums[right_root]
        smallest_position[left_root] = min(
            smallest_position[left_root], smallest_position[right_root]
        )

    if output_is_null or capacity is not None and capacity < count:
        return -2, b""
    payload = bytes(smallest_position[find(position)] for position in range(count))
    return count, payload
