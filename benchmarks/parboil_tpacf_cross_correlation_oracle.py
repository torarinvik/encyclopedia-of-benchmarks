"""Independent direct-bin oracle for bounded Parboil TPACF cross-correlation."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

NUM_BINS = 20
MAX_POINTS = 4
MAX_INPUT_LENGTH = 26
SCALE = 1_000_000
PI_VALUE = 3.141592653589793238462643383279502884


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _boundaries() -> list[float]:
    values = []
    for index in range(NUM_BINS + 1):
        exponent = math.log10(1.0) + float(index) * 1.0 / 5.0
        arcminutes = math.pow(10.0, exponent)
        radians = arcminutes / 60.0 * (PI_VALUE / 180.0)
        values.append(_f32(math.cos(radians)))
    return values


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        values is not None and not isinstance(values, (list, tuple))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
    ):
        return -1, b""
    if input_is_null or values is None or not 8 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""
    data_count, random_count = values[0], values[1]
    if not 1 <= data_count <= MAX_POINTS or not 1 <= random_count <= MAX_POINTS:
        return -1, b""
    if len(values) != 2 + 3 * (data_count + random_count):
        return -1, b""
    if any(value < -SCALE or value > SCALE for value in values[2:]):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < NUM_BINS:
        return -2, b""

    def point(offset: int) -> tuple[float, float, float]:
        return tuple(_f32(_f32(values[offset + axis]) / _f32(SCALE)) for axis in range(3))

    data = [point(2 + 3 * i) for i in range(data_count)]
    random_base = 2 + 3 * data_count
    randoms = [point(random_base + 3 * i) for i in range(random_count)]
    boundaries = _boundaries()
    histogram = [0] * NUM_BINS
    # The source binary-searches descending thresholds; this oracle scans them.
    for random_point in randoms:
        for data_point in data:
            products = [_f32(data_point[axis] * random_point[axis]) for axis in range(3)]
            dot = _f32(_f32(products[0] + products[1]) + products[2])
            for bin_index in range(NUM_BINS):
                if boundaries[bin_index] > dot >= boundaries[bin_index + 1]:
                    histogram[bin_index] += 1
                    break
    return NUM_BINS, bytes(histogram)
