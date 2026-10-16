"""Oracle for the deterministic isList=FALSE mode of the pinned R source."""

from __future__ import annotations

MAX_SAMPLES = 12
MAX_FOLDS = 12
MAX_INPUT_LENGTH = 2
FOLD_COUNT_SHIFT = 48


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    sample_count, fold_count = values
    if not 1 <= sample_count <= MAX_SAMPLES or not 1 <= fold_count <= MAX_FOLDS:
        return -1
    samples_per_fold = (sample_count + fold_count - 1) // fold_count
    result = sample_count << FOLD_COUNT_SHIFT
    for index in range(1, sample_count + 1):
        fold = (index + samples_per_fold - 1) // samples_per_fold
        result |= fold << (4 * (index - 1))
    return result
