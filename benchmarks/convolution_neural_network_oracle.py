"""Bounded oracle for deterministic CNN inference with explicit model parameters."""

from __future__ import annotations

import math
import struct

MAX_IMAGE_SIDE = 8
MAX_KERNEL_SIDE = 4
MAX_FILTERS = 3
MAX_HIDDEN = 8
MAX_OUTPUTS = 4
MAX_ENTRY_MICRO = 1_000_000
SCALE = 1_000_000.0
MAX_INPUT_LENGTH = 2048
MAX_OUTPUT_BYTES = MAX_OUTPUTS * 8


def _sigmoid(value: float) -> float:
    return 1.0 / (1.0 + math.exp(-value))


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return rounded neural-network probabilities, or an ABI error."""
    if (not isinstance(values, (list, tuple)) or not 7 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    image_side, kernel_side, stride, filters, pool_side, hidden, outputs = values[:7]
    if not 2 <= image_side <= MAX_IMAGE_SIDE or not 1 <= kernel_side <= MAX_KERNEL_SIDE:
        return -1, b""
    if not 1 <= stride <= 4 or not 1 <= filters <= MAX_FILTERS:
        return -1, b""
    if not 1 <= pool_side <= 2 or not 1 <= hidden <= MAX_HIDDEN or not 1 <= outputs <= MAX_OUTPUTS:
        return -1, b""
    if kernel_side > image_side:
        return -1, b""
    conv_side = (image_side - kernel_side) // stride + 1
    if conv_side < pool_side or conv_side % pool_side != 0:
        return -1, b""
    pooled_side = conv_side // pool_side
    feature_count = filters * pooled_side * pooled_side
    expected_length = (7 + image_side * image_side + filters * kernel_side * kernel_side + filters
                       + hidden * feature_count + outputs * hidden + hidden + outputs)
    if len(values) != expected_length:
        return -1, b""

    position = 7
    image_raw = values[position:position + image_side * image_side]
    position += image_side * image_side
    kernel_count = filters * kernel_side * kernel_side
    kernels_raw = values[position:position + kernel_count]
    position += kernel_count
    conv_bias_raw = values[position:position + filters]
    position += filters
    hidden_weights_raw = values[position:position + hidden * feature_count]
    position += hidden * feature_count
    output_weights_raw = values[position:position + outputs * hidden]
    position += outputs * hidden
    hidden_bias_raw = values[position:position + hidden]
    position += hidden
    output_bias_raw = values[position:position + outputs]
    all_parameters = (image_raw + kernels_raw + conv_bias_raw + hidden_weights_raw
                      + output_weights_raw + hidden_bias_raw + output_bias_raw)
    if any(value < -MAX_ENTRY_MICRO or value > MAX_ENTRY_MICRO for value in all_parameters):
        return -1, b""
    if any(value < 0 for value in image_raw):
        return -1, b""
    if any(value < -500_000 or value > 500_000
           for value in kernels_raw + hidden_weights_raw + output_weights_raw):
        return -1, b""

    image = [value / SCALE for value in image_raw]
    kernels = [[value / SCALE for value in kernels_raw[index * kernel_side * kernel_side:
                                                        (index + 1) * kernel_side * kernel_side]]
               for index in range(filters)]
    conv_bias = [value / SCALE for value in conv_bias_raw]
    hidden_weights = [[value / SCALE for value in hidden_weights_raw[index * feature_count:
                                                                       (index + 1) * feature_count]]
                      for index in range(hidden)]
    output_weights = [[value / SCALE for value in output_weights_raw[index * hidden:
                                                                      (index + 1) * hidden]]
                      for index in range(outputs)]
    hidden_bias = [value / SCALE for value in hidden_bias_raw]
    output_bias = [value / SCALE for value in output_bias_raw]

    feature_maps: list[list[list[float]]] = []
    for feature in range(filters):
        rows: list[list[float]] = []
        for top in range(0, image_side - kernel_side + 1, stride):
            row: list[float] = []
            for left in range(0, image_side - kernel_side + 1, stride):
                total = 0.0
                for kernel_row in range(kernel_side):
                    for kernel_column in range(kernel_side):
                        pixel = image[(top + kernel_row) * image_side + left + kernel_column]
                        weight = kernels[feature][kernel_row * kernel_side + kernel_column]
                        total += pixel * weight
                row.append(_sigmoid(total - conv_bias[feature]))
            rows.append(row)
        feature_maps.append(rows)

    flattened: list[float] = []
    pool_area = pool_side * pool_side
    for feature_map in feature_maps:
        for top in range(0, conv_side, pool_side):
            for left in range(0, conv_side, pool_side):
                total = 0.0
                for row in range(pool_side):
                    for column in range(pool_side):
                        total += feature_map[top + row][left + column]
                flattened.append(total / pool_area)

    hidden_output: list[float] = []
    for unit in range(hidden):
        total = 0.0
        for index in range(feature_count):
            total += flattened[index] * hidden_weights[unit][index]
        hidden_output.append(_sigmoid(total - hidden_bias[unit]))
    result: list[float] = []
    for unit in range(outputs):
        total = 0.0
        for index in range(hidden):
            total += hidden_output[index] * output_weights[unit][index]
        result.append(round(_sigmoid(total - output_bias[unit]), 3))

    encoded = struct.pack("<" + "d" * outputs, *result)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(encoded) > capacity:
            return -2, b""
    return len(encoded), encoded
