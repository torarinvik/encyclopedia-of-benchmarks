"""Reference for trace-driven Barnsley fern point generation."""

from __future__ import annotations

import struct

MAX_ITERATIONS = 4096
SAMPLE_BINS = 10_000
OUTPUT_SCALE = 1_000_000
TRANSFORMATIONS = (
    (0.00, 0.00, 0.00, 0.16, 0.00, 0.00),
    (0.85, 0.04, -0.04, 0.85, 0.00, 1.60),
    (0.20, -0.26, 0.23, 0.22, 0.00, 1.60),
    (-0.15, 0.28, 0.26, 0.24, 0.00, 0.44),
)


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 1
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    iterations = values[0]
    samples = values[1:]
    if (not 1 <= iterations <= MAX_ITERATIONS or len(values) != iterations
            or any(not 0 <= sample < SAMPLE_BINS for sample in samples)):
        return -1, b""

    x = y = 0.0
    points = [0, 0]
    for sample in samples:
        index = 0 if sample < 100 else 1 if sample < 8_600 else 2 if sample < 9_300 else 3
        a, b, c, d, e, f = TRANSFORMATIONS[index]
        new_x = round(a * x + b * y + e, 12)
        new_y = round(c * x + d * y + f, 12)
        x, y = new_x, new_y
        points.extend((round(x * OUTPUT_SCALE), round(y * OUTPUT_SCALE)))
    output = struct.pack("<" + "q" * len(points), *points)
    return len(output), output
