"""Source-faithful oracle for the pinned Python regression decision tree."""

from __future__ import annotations

import math
from collections.abc import Sequence


MIN_DEPTH = 1
MAX_DEPTH = 6
MIN_LEAF_SIZE = 1
MAX_LEAF_SIZE = 6
MIN_SAMPLE_COUNT = 2
MAX_SAMPLE_COUNT = 12
MIN_QUERY_COUNT = 1
MAX_QUERY_COUNT = 12
MIN_VALUE = -8
MAX_VALUE = 8
MAX_INPUT_LENGTH = 3 + 2 * MAX_SAMPLE_COUNT + 1 + MAX_QUERY_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = 1 + MAX_QUERY_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _number(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    try:
        number = float(value)
    except OverflowError:
        return None
    if not math.isfinite(number):
        return None
    return number


def _integer(value: float, minimum: int, maximum: int) -> int | None:
    if value < minimum or value > maximum or value != math.trunc(value):
        return None
    return int(value)


def _mse(values: Sequence[float], prediction: float) -> float:
    return sum((value - prediction) ** 2 for value in values) / len(values)


def _train(x: Sequence[float], y: Sequence[float], depth: int, min_leaf_size: int):
    """Return (leaf prediction, boundary, left, right) nodes.

    The pinned source passes feature slices to ``mean_squared_error`` while
    using the corresponding target means as predictions. This intentionally
    preserves that source behavior.
    """
    if len(x) < 2 * min_leaf_size or depth == 1:
        return (sum(y) / len(y), None, None, None)

    best_split = 0
    min_error = 2 * _mse(x, sum(y) / len(y))
    for split in range(len(x)):
        if split < min_leaf_size or len(x) - split < min_leaf_size:
            continue
        left_error = _mse(x[:split], sum(y[:split]) / split)
        right_count = len(x) - split
        right_error = _mse(x[split:], sum(y[split:]) / right_count)
        error = left_error + right_error
        if error < min_error:
            best_split = split
            min_error = error

    if best_split == 0:
        return (sum(y) / len(y), None, None, None)
    return (
        None,
        x[best_split],
        _train(x[:best_split], y[:best_split], depth - 1, min_leaf_size),
        _train(x[best_split:], y[best_split:], depth - 1, min_leaf_size),
    )


def _predict(node, query: float) -> float:
    prediction, boundary, left, right = node
    if prediction is not None:
        return prediction
    return _predict(right if query >= boundary else left, query)


def expected_output(
    values: Sequence[object],
    *,
    input_length: int | None = None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, list[float]]:
    """Return the result code and output for one bounded framed input."""
    if input_length is None:
        input_length = len(values)
    if input_is_null or input_length < 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, []
    if input_length != len(values) or input_length < 8:
        return INVALID_RESULT, []

    parsed = [_number(value) for value in values]
    if any(value is None for value in parsed):
        return INVALID_RESULT, []
    numeric = [float(value) for value in parsed]

    depth = _integer(numeric[0], MIN_DEPTH, MAX_DEPTH)
    min_leaf_size = _integer(numeric[1], MIN_LEAF_SIZE, MAX_LEAF_SIZE)
    sample_count = _integer(numeric[2], MIN_SAMPLE_COUNT, MAX_SAMPLE_COUNT)
    if depth is None or min_leaf_size is None or sample_count is None:
        return INVALID_RESULT, []
    query_count_index = 3 + 2 * sample_count
    if input_length <= query_count_index:
        return INVALID_RESULT, []
    query_count = _integer(
        numeric[query_count_index], MIN_QUERY_COUNT, MAX_QUERY_COUNT
    )
    if query_count is None or input_length != query_count_index + 1 + query_count:
        return INVALID_RESULT, []
    if input_length > MAX_INPUT_LENGTH:
        return INVALID_RESULT, []

    x = numeric[3 : 3 + sample_count]
    y = numeric[3 + sample_count : query_count_index]
    queries = numeric[query_count_index + 1 :]
    if any(_integer(value, MIN_VALUE, MAX_VALUE) is None for value in x + y + queries):
        return INVALID_RESULT, []

    node = _train(x, y, depth, min_leaf_size)
    output = [float(query_count)] + [_predict(node, query) for query in queries]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output

