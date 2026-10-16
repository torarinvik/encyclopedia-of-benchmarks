"""Oracle for bounded 3D Pythagorean distance between two integer points."""
import math

MAX_INPUT_LENGTH = 6
MAX_COORDINATE = 1_000_000
INVALID_RESULT = -1e300

def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(x) is not int or abs(x) > MAX_COORDINATE for x in values):
        return INVALID_RESULT
    dx = values[3] - values[0]
    dy = values[4] - values[1]
    dz = values[5] - values[2]
    return math.sqrt(float(dx * dx) + float(dy * dy) + float(dz * dz))
