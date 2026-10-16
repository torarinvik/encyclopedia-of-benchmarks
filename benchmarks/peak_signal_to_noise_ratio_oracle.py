"""Oracle for the shared non-identical-image PSNR domain."""
import math

MAX_PIXELS = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_PIXELS
MAX_ABSOLUTE_PIXEL_DIFFERENCE = 15
INVALID_RESULT = -1e300


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return INVALID_RESULT
    count = values[0]
    if not 1 <= count <= MAX_PIXELS or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    pixels = values[1:]
    if any(not 0 <= x <= 255 for x in pixels):
        return INVALID_RESULT
    original = pixels[:count]
    compressed = pixels[count:]
    if any(abs(a - b) > MAX_ABSOLUTE_PIXEL_DIFFERENCE
           for a, b in zip(original, compressed)):
        return INVALID_RESULT
    squared_sum = sum((a - b) * (a - b) for a, b in zip(original, compressed))
    mse = squared_sum / count
    if mse == 0:
        # Python returns 100 here, while the pinned Rust port returns +infinity.
        return INVALID_RESULT
    return 20.0 * math.log10(255.0 / math.sqrt(mse))
