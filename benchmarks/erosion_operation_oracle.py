"""Runtime oracle for bounded binary cross-kernel erosion."""

MAX_HEIGHT = 6
MAX_WIDTH = 6
MAX_INPUT_LENGTH = 2 + MAX_HEIGHT * MAX_WIDTH


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1
    height, width = values[:2]
    if not 1 <= height <= MAX_HEIGHT or not 1 <= width <= MAX_WIDTH:
        return -1
    if len(values) != 2 + height * width or any(x not in (0, 1) for x in values[2:]):
        return -1
    image = values[2:]
    result = 0
    for row in range(height):
        for column in range(width):
            if all(0 <= row + dr < height and 0 <= column + dc < width
                   and image[(row + dr) * width + column + dc] == 1
                   for dr, dc in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1))):
                result |= 1 << (row * width + column)
    return result
