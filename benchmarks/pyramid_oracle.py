"""Oracle for the pinned JavaScript regular square pyramid formulas."""
import math
MAX_INPUT_LENGTH = 3
INVALID_RESULT = -1e300
SCALE = 1000
MAX_DIMENSION_MILLI = 10_000_000


def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) != 3 or any(type(x) is not int for x in values):
        return INVALID_RESULT
    mode, base_milli, height_milli = values
    if mode not in (0, 1) or not (1 <= base_milli <= MAX_DIMENSION_MILLI) or not (1 <= height_milli <= MAX_DIMENSION_MILLI):
        return INVALID_RESULT
    base = base_milli / SCALE
    height = height_milli / SCALE
    base_area = base ** 2
    if mode == 0:
        return (base_area * height) / 3
    return base_area + ((base * 4) / 2) * math.sqrt((base / 2) ** 2 + height**2)

