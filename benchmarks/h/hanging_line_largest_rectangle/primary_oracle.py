"""Prior-link reference for the bounded hanging-line histogram profile."""

INVALID = -(1 << 63)
MAX_INPUT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_HEIGHT = 1_000_000


def expected_result(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool:
        return INVALID
    if input_length is not None and (
        type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID
    actual_length = input_length if input_length is not None else (
        len(values) if isinstance(values, (list, tuple)) else 0
    )
    if input_is_null or values is None:
        return 0 if actual_length == 0 else INVALID
    if not isinstance(values, (list, tuple)) or len(values) != actual_length:
        return INVALID
    if len(values) > MAX_INPUT_LENGTH or any(
        type(height) is not int or not 0 <= height <= MAX_HEIGHT
        for height in values
    ):
        return INVALID

    count = len(values)
    left = [0] * count
    for index, height in enumerate(values):
        boundary = index
        while boundary > 0 and values[boundary - 1] >= height:
            boundary = left[boundary - 1]
        left[index] = boundary

    right = [0] * count
    for index in range(count - 1, -1, -1):
        boundary = index
        while boundary + 1 < count and values[boundary + 1] >= values[index]:
            boundary = right[boundary + 1]
        right[index] = boundary

    best = 0
    for index, height in enumerate(values):
        area = height * (right[index] - left[index] + 1)
        if area > best:
            best = area
    return best
