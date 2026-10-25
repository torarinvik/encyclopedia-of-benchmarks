"""Independent oracle for the bounded LAME stereo mid-side conversion profile."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_CHANNEL_SAMPLES = 32
MAX_INPUT_LENGTH = 1 + 2 * MAX_CHANNEL_SAMPLES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_CHANNEL_SAMPLES
SCALE = math.sqrt(2.0) * 0.5

def expected_output(values: Sequence[float] | None,
                    output_capacity: int | None = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(x) not in (int, float) or not math.isfinite(float(x))
                   for x in values)):
        return -1, ()
    if not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, ()
    count_value = values[0]
    if type(count_value) not in (int, float) or not float(count_value).is_integer():
        return -1, ()
    count = int(count_value)
    if not 1 <= count <= MAX_CHANNEL_SAMPLES or len(values) != 1 + 2 * count:
        return -1, ()
    samples = tuple(float(x) for x in values[1:])
    if any(x < -16.0 or x > 16.0 for x in samples):
        return -1, ()

    left = samples[:count]
    right = samples[count:]
    output: list[float] = []
    for l, r in zip(left, right):
        output.append((l + r) * SCALE)
        output.append((l - r) * SCALE)
    result = tuple(output)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, ()
    if output_is_null or output_capacity < len(result):
        return -2, ()
    return len(result), result

oracle = expected_output
