"""Deterministic scalar-training-step contract for the pinned BPNN demo."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1
SCALE = 1_000_000.0


def back_propagation_step(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 7
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    x_q, target_q, hidden_weight_q, hidden_bias_q, output_weight_q, output_bias_q, rate_q = values
    if (not -1_000_000 <= x_q <= 1_000_000
            or not -1_000_000 <= target_q <= 1_000_000
            or any(not -2_000_000 <= value <= 2_000_000
                   for value in (hidden_weight_q, hidden_bias_q, output_weight_q, output_bias_q))
            or not 1 <= rate_q <= 300_000):
        return INVALID_RESULT, b""

    x = x_q / SCALE
    target = target_q / SCALE
    hidden_weight = hidden_weight_q / SCALE
    hidden_bias = hidden_bias_q / SCALE
    output_weight = output_weight_q / SCALE
    output_bias = output_bias_q / SCALE
    learning_rate = rate_q / SCALE

    hidden_net = hidden_weight * x - hidden_bias
    hidden = 1.0 / (1.0 + math.exp(-hidden_net))
    output_net = output_weight * hidden - output_bias
    prediction = 1.0 / (1.0 + math.exp(-output_net))
    loss = (target - prediction) ** 2

    loss_gradient = 2.0 * (prediction - target)
    output_delta = loss_gradient * prediction * (1.0 - prediction)
    output_weight_gradient = output_delta * hidden
    output_bias_gradient = -output_delta
    hidden_gradient = output_delta * output_weight
    hidden_delta = hidden_gradient * hidden * (1.0 - hidden)
    hidden_weight_gradient = hidden_delta * x
    hidden_bias_gradient = -hidden_delta

    # The source uses weight - learning_rate * gradient and bias - learning_rate * (-delta).
    updated_hidden_weight = hidden_weight - learning_rate * hidden_weight_gradient
    updated_hidden_bias = hidden_bias - learning_rate * hidden_bias_gradient
    updated_output_weight = output_weight - learning_rate * output_weight_gradient
    updated_output_bias = output_bias - learning_rate * output_bias_gradient

    def quantize(value: float) -> int:
        scaled = value * SCALE
        return int(scaled + 0.5) if scaled >= 0.0 else int(scaled - 0.5)

    output_values = (quantize(loss), quantize(hidden), quantize(prediction),
                     quantize(updated_hidden_weight), quantize(updated_hidden_bias),
                     quantize(updated_output_weight), quantize(updated_output_bias))
    return 56, b"".join(struct.pack("<q", value) for value in output_values)

