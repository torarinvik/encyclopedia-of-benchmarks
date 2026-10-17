"""Oracle for bounded integer logistic-regression classification predictions."""

from __future__ import annotations

MAX_ROWS = 63
MAX_FEATURES = 32
MAX_VALID_INPUT_VALUES = 2 + MAX_ROWS * MAX_FEATURES + MAX_FEATURES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_VALUES + 1
MIN_FEATURE_VALUE = -1000
MAX_FEATURE_VALUE = 1000
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the packed 0/1 prediction mask, or -1 when input is invalid.

    Input is ``[row_count, feature_count, X row-major..., theta...]``. A row
    predicts one when its integer dot product with theta is nonnegative, which
    preserves the pinned implementation's inclusive 0.5 probability threshold.
    """
    if (not isinstance(values, (list, tuple))
            or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return INVALID_RESULT

    row_count, feature_count = values[0], values[1]
    if not (1 <= row_count <= MAX_ROWS and 1 <= feature_count <= MAX_FEATURES):
        return INVALID_RESULT

    expected_length = 2 + row_count * feature_count + feature_count
    if len(values) != expected_length:
        return INVALID_RESULT

    features_end = 2 + row_count * feature_count
    features = values[2:features_end]
    theta = values[features_end:]
    if any(value < MIN_FEATURE_VALUE or value > MAX_FEATURE_VALUE
           for value in (*features, *theta)):
        return INVALID_RESULT

    mask = 0
    for row in range(row_count):
        start = row * feature_count
        score = sum(features[start + column] * theta[column]
                    for column in range(feature_count))
        if score >= 0:
            mask |= 1 << row

    # The row bound ensures the sign bit is never set.
    assert 0 <= mask <= I64_MAX
    return mask
