"""Oracle for the randomized Rust 2D k-means source variant."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
U53_MAX = (1 << 53) - 1
DENOMINATOR = 1 << 53
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the final label bitmask, or -1 when framing/domain is invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > 11
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != 10
    ):
        return INVALID_RESULT

    n, max_iter = values[:2]
    draws = values[2:6]
    points = values[6:]
    if (
        n != 4
        or not 1 <= max_iter <= 16
        or any(not 0 <= draw <= U53_MAX for draw in draws)
        or draws[1] != 0
        or draws[3] != 0
        or draws[0] == draws[2]
        or any(not -16 <= point <= 16 for point in points)
        or any(left >= right for left, right in zip(points, points[1:]))
        or points[1] >= 0
        or points[2] <= 1
    ):
        return INVALID_RESULT

    denominator = float(DENOMINATOR)
    centers = [
        [draws[0] / denominator, 0.0],
        [draws[2] / denominator, 0.0],
    ]
    labels = [0, 0, 0, 0]
    for _ in range(max_iter):
        counts = [0, 0]
        sums = [[0.0, 0.0], [0.0, 0.0]]
        for index, point in enumerate(points):
            first_distance = (float(point) - centers[0][0]) ** 2 + centers[0][1] ** 2
            second_distance = (float(point) - centers[1][0]) ** 2 + centers[1][1] ** 2
            label = 1 if second_distance < first_distance else 0
            labels[index] = label
            counts[label] += 1
            sums[label][0] += float(point)
            sums[label][1] += 0.0
        if any(count == 0 for count in counts):
            return INVALID_RESULT
        for cluster in range(2):
            centers[cluster] = [
                sums[cluster][0] / counts[cluster],
                sums[cluster][1] / counts[cluster],
            ]
    return sum(label << index for index, label in enumerate(labels))
