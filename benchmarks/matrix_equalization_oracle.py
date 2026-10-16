"""Independent bounded oracle for the matrix_equalization array benchmark."""

from __future__ import annotations

MAX_VECTOR_LENGTH = 64
MAX_VALID_INPUT_LENGTH = 1 + MAX_VECTOR_LENGTH
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the minimum update count for a packed [step, vector...] input."""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    vector = values[1:]
    vector_length = len(vector)
    if vector_length > MAX_VECTOR_LENGTH:
        return INVALID_RESULT

    step_size = values[0]
    if not 1 <= step_size <= vector_length:
        return INVALID_RESULT

    minimum_updates = vector_length
    for target_index, target in enumerate(vector):
        if target in vector[:target_index]:
            continue

        updates = 0
        index = 0
        while index < vector_length:
            if vector[index] == target:
                index += 1
            else:
                updates += 1
                index += step_size
        minimum_updates = min(minimum_updates, updates)

    return minimum_updates
