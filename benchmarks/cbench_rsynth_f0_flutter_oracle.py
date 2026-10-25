"""Oracle for RSynth's three-sine pitch-flutter adjustment."""
import math
from collections.abc import Sequence

MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1
PI = 3.1415927

def expected_result(values: Sequence[int] | None) -> int:
    if values is None or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(v) is not int for v in values) or len(values) != 3:
        return INVALID_RESULT
    f0_hz10, flutter, time_count = values
    if not 0 <= f0_hz10 <= 20000 or not 0 <= flutter <= 100 or not 0 <= time_count <= 1_000_000:
        return INVALID_RESULT
    original_f0 = f0_hz10 // 10
    fla = float(flutter) / 50.0
    flb = float(original_f0) / 100.0
    flc = math.sin(2.0 * PI * 12.7 * time_count)
    fld = math.sin(2.0 * PI * 7.1 * time_count)
    fle = math.sin(2.0 * PI * 4.7 * time_count)
    delta = fla * flb * (flc + fld + fle) * 10.0
    return f0_hz10 + int(delta)

oracle = expected_result
