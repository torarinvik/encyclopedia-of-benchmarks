"""Oracle for the pinned Python multilayer perceptron classifier."""

from __future__ import annotations

import math
from collections.abc import Sequence


MAX_EPOCHS = 12
INPUT_LENGTH = 15
MAX_PARSEABLE_INPUT_LENGTH = 16
MAX_OUTPUT_LENGTH = 26
INVALID_RESULT = -1
OUTPUT_ERROR = -2

# First model after a fresh import: default_rng(42), with the source's
# row-major standard_normal matrix draws and He scaling for input/hidden size 2.
_INITIAL_W1 = (
    (0.30471707975443135, -1.0399841062404955),
    (0.7504511958064572, 0.9405647163912139),
    (-1.9510351886538364, -1.302179506862318),
)
_INITIAL_W2 = (
    (0.12784040316728537, -0.3162425923435822, -0.016801157504288795),
    (-0.85304392757358, 0.8793979748628286, 0.7777919354289483),
)


def _finite_float(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    try:
        result = float(value)
    except OverflowError:
        return None
    return result if math.isfinite(result) else None


def _integer(value: float, low: int, high: int) -> int | None:
    if value < low or value > high or value != math.trunc(value):
        return None
    return int(value)


def expected_output(
    values: Sequence[object] | None,
    *,
    input_length: int | None = None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, list[float]]:
    if not isinstance(input_is_null, bool) or not isinstance(output_is_null, bool):
        return INVALID_RESULT, []
    if input_is_null or values is None:
        return INVALID_RESULT, []
    if input_length is None:
        input_length = len(values)
    if (
        isinstance(input_length, bool)
        or not isinstance(input_length, int)
        or input_length < 0
        or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT, []
    if output_capacity is not None and (
        isinstance(output_capacity, bool)
        or not isinstance(output_capacity, int)
        or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length != len(values) or input_length != INPUT_LENGTH:
        return INVALID_RESULT, []

    parsed = [_finite_float(value) for value in values]
    if any(value is None for value in parsed):
        return INVALID_RESULT, []
    data = [float(value) for value in parsed]

    epochs = _integer(data[0], 1, MAX_EPOCHS)
    learning_rate = data[1]
    gamma = data[2]
    if epochs is None or learning_rate not in (0.05, 0.1, 0.2) or gamma not in (0.5, 0.75, 1.0):
        return INVALID_RESULT, []

    features = [data[3 + row * 2 : 5 + row * 2] for row in range(4)]
    labels = [_integer(data[11 + row], 0, 2) for row in range(4)]
    if any(label is None for label in labels):
        return INVALID_RESULT, []
    if any(value < -2.0 or value > 2.0 or value * 4.0 != math.trunc(value * 4.0)
           for row in features for value in row):
        return INVALID_RESULT, []

    w1 = [list(row) for row in _INITIAL_W1]
    w2 = [list(row) for row in _INITIAL_W2]
    rates = learning_rate
    accuracy_history: list[float] = []
    loss_history: list[float] = []

    for _epoch in range(epochs):
        for row_index in range(3):
            row = [*features[row_index], 1.0]
            z1 = [sum(row[i] * w1[i][j] for i in range(3)) for j in range(2)]
            hidden = [max(0.0, value) for value in z1]
            z2 = [sum(hidden[j] * w2[j][k] for j in range(2)) for k in range(3)]
            target = [0.99 if label == labels[row_index] else 0.0 for label in range(3)]
            delta_out = [z2[k] - target[k] for k in range(3)]
            delta_hidden = [
                sum(delta_out[k] * w2[j][k] for k in range(3)) * (1.0 if z1[j] > 0.0 else 0.0)
                for j in range(2)
            ]
            grad_w2 = [[hidden[j] * delta_out[k] for k in range(3)] for j in range(2)]
            grad_w1 = [[row[i] * delta_hidden[j] for j in range(2)] for i in range(3)]
            for i in range(3):
                for j in range(2):
                    w1[i][j] -= rates * grad_w1[i][j]
            for j in range(2):
                for k in range(3):
                    w2[j][k] -= rates * grad_w2[j][k]

        test_row = [*features[3], 1.0]
        z1 = [sum(test_row[i] * w1[i][j] for i in range(3)) for j in range(2)]
        hidden = [max(0.0, value) for value in z1]
        output = [sum(hidden[j] * w2[j][k] for j in range(2)) for k in range(3)]
        predicted_class = max(range(3), key=lambda index: output[index])
        accuracy_history.append(1.0 if predicted_class == labels[3] else 0.0)
        target = [0.99 if label == labels[3] else 0.0 for label in range(3)]
        loss_history.append(sum((output[k] - target[k]) ** 2 for k in range(3)) / 2.0)
        rates *= gamma

    mean_accuracy = sum(accuracy_history) / epochs
    output_values = [float(epochs), *accuracy_history, *loss_history, mean_accuracy]
    if output_is_null or (output_capacity is not None and output_capacity < len(output_values)):
        return OUTPUT_ERROR, []
    return len(output_values), output_values
