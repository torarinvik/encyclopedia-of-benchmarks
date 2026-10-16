from collections.abc import Sequence
MAX_INPUT_LENGTH = 9
INVALID_RESULT = -1.0e300

def expected_result(values: Sequence[int]) -> float:
    if not isinstance(values, (list, tuple)) or len(values) != 9:
        return INVALID_RESULT
    if any(type(value) is not int or not 0 <= value <= 255 for value in values):
        return INVALID_RESULT
    # ksize=1 source kernel, evaluated by filter2D at output (0,0) with
    # anchor=(0,0): the kernel's center maps to source pixel (1,1).
    return float(4 * values[4] - values[1] - values[3] - values[5] - values[7])
