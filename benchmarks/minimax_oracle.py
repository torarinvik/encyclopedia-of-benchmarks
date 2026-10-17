"""Independent bounded oracle for full binary-tree minimax evaluation."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -2_147_483_649
MAX_LEAF_COUNT = 32
MAX_INPUT_LENGTH = 2 + MAX_LEAF_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
) -> int:
    """Validate the packed input and reduce the score levels bottom-up."""
    if values is None:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    leaf_count, first_turn_is_max = values[:2]
    if (not 1 <= leaf_count <= MAX_LEAF_COUNT
            or leaf_count & (leaf_count - 1)
            or first_turn_is_max not in (0, 1)
            or len(values) != 2 + leaf_count):
        return INVALID_RESULT
    scores = values[2:]
    if any(score < I32_MIN or score > I32_MAX for score in scores):
        return INVALID_RESULT

    maximizing = first_turn_is_max == 1
    while len(scores) > 1:
        if maximizing:
            scores = [max(scores[index], scores[index + 1])
                      for index in range(0, len(scores), 2)]
        else:
            scores = [min(scores[index], scores[index + 1])
                      for index in range(0, len(scores), 2)]
        maximizing = not maximizing
    return scores[0]
