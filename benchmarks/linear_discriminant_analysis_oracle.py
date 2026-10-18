"""Oracle for the bounded scalar Linear Discriminant Analysis pipeline."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_CLASSES = 2
MAX_CLASSES = 4
MIN_CLASS_SAMPLES = 2
MAX_CLASS_SAMPLES = 6
MAX_TOTAL_SAMPLES = 16
MIN_SAMPLE = -32
MAX_SAMPLE = 32
MIN_SCORE_MARGIN = 1e-8
MAX_VALID_INPUT_LENGTH = 1 + MAX_CLASSES + MAX_TOTAL_SAMPLES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_TOTAL_SAMPLES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 0.0
RELATIVE_TOLERANCE = 0.0


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _exact_int(value: int | float) -> int | None:
    number = float(value)
    if not number.is_integer():
        return None
    return int(number)


def _parse(values: Sequence[int | float] | None) -> tuple[list[list[float]], int] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(not _finite_number(value) for value in values)
    ):
        return None

    class_count = _exact_int(values[0])
    if class_count is None or not MIN_CLASSES <= class_count <= MAX_CLASSES:
        return None
    if len(values) < 1 + class_count:
        return None
    counts: list[int] = []
    for value in values[1 : 1 + class_count]:
        count = _exact_int(value)
        if count is None or not MIN_CLASS_SAMPLES <= count <= MAX_CLASS_SAMPLES:
            return None
        counts.append(count)
    total_count = sum(counts)
    if total_count > MAX_TOTAL_SAMPLES or len(values) != 1 + class_count + total_count:
        return None

    groups: list[list[float]] = []
    offset = 1 + class_count
    for count in counts:
        group: list[float] = []
        for value in values[offset : offset + count]:
            sample = _exact_int(value)
            if sample is None or not MIN_SAMPLE <= sample <= MAX_SAMPLE:
                return None
            group.append(float(sample))
        if sum(int(sample) for sample in group) % count != 0:
            return None
        groups.append(group)
        offset += count

    means = [sum(group) / len(group) for group in groups]
    squared_differences = [
        (sample - means[class_index]) ** 2
        for class_index, group in enumerate(groups)
        for sample in group
    ]
    variance = 1.0 / (total_count - class_count) * sum(squared_differences)
    if not math.isfinite(variance) or variance <= 0.0:
        return None
    return groups, total_count


def _predict(groups: list[list[float]], total_count: int) -> list[float] | None:
    class_count = len(groups)
    means = [sum(group) / len(group) for group in groups]
    probabilities = [len(group) / total_count for group in groups]
    variance = 1.0 / (total_count - class_count) * sum(
        (sample - means[class_index]) ** 2
        for class_index, group in enumerate(groups)
        for sample in group
    )
    if not math.isfinite(variance) or variance <= 0.0:
        return None

    predictions: list[float] = []
    for group in groups:
        for x in group:
            scores = [
                x * (means[k] / variance)
                - (means[k] ** 2 / (2 * variance))
                + math.log(probabilities[k])
                for k in range(class_count)
            ]
            # Python list.index(max(...)) selects the first maximum.
            winner = scores.index(max(scores))
            ordered = sorted(scores, reverse=True)
            if ordered[0] - ordered[1] < MIN_SCORE_MARGIN:
                return None
            predictions.append(float(winner))
    return predictions


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return class-major predicted class ids, or None for invalid input."""
    parsed = _parse(values)
    if parsed is None:
        return None
    groups, total_count = parsed
    output = _predict(groups, total_count)
    if output is None or len(output) > MAX_OUTPUT_ELEMENTS:
        return None
    return output


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return status and class-major prediction ids for the float-slice ABI."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, []
    return len(output), output
