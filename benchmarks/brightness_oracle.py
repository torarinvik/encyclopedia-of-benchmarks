"""Contract oracle for the fixed RGB brightness nearest-neighbor classifier."""

from __future__ import annotations

MAX_INPUT_LENGTH = 4  # permits one extra component in a malformed workload case

# The four columns in the pinned MATLAB-Octave source are R, G, B, and label.
TRAINING_ROWS = (
    (2, 99, 255, 1),
    (37, 44, 58, 0),
    (139, 169, 229, 1),
    (14, 255, 10, 1),
    (2, 28, 1, 0),
    (20, 33, 20, 0),
    (252, 227, 65, 1),
    (71, 65, 24, 0),
    (168, 80, 80, 1),
    (119, 35, 90, 0),
    (186, 13, 126, 1),
)


def expected_result(values: list[int]) -> int:
    """Return the label of the first nearest training RGB row, or -1 if invalid."""
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or len(values) != 3
            or any(type(channel) is not int or not 0 <= channel <= 255 for channel in values)):
        return -1

    red, green, blue = values
    best_distance = None
    best_label = -1
    for sample_red, sample_green, sample_blue, label in TRAINING_ROWS:
        distance = ((red - sample_red) ** 2
                    + (green - sample_green) ** 2
                    + (blue - sample_blue) ** 2)
        if best_distance is None or distance < best_distance:
            best_distance = distance
            best_label = label
    return best_label
