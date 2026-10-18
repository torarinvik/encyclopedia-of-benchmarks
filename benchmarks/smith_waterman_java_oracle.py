"""Oracle for the pinned Java SmithWaterman.align scalar-score contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SEQUENCE_LENGTH = 16
MAX_VALID_INPUT_LENGTH = 5 + 2 * MAX_SEQUENCE_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_MATCH = 1
MAX_MATCH = 5
MIN_MISMATCH = -5
MAX_MISMATCH = -1
MIN_GAP = -5
MAX_GAP = -1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_length: int | None = None) -> tuple[int, int, int, int, list[int], list[int]] | None:
    if not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 5:
        return None
    query_length, subject_length, match_score, mismatch_score, gap_score = values[:5]
    if not 0 <= query_length <= MAX_SEQUENCE_LENGTH or not 0 <= subject_length <= MAX_SEQUENCE_LENGTH:
        return None
    if not MIN_MATCH <= match_score <= MAX_MATCH:
        return None
    if not MIN_MISMATCH <= mismatch_score <= MAX_MISMATCH:
        return None
    if not MIN_GAP <= gap_score <= MAX_GAP:
        return None
    if len(values) != 5 + query_length + subject_length:
        return None
    query = list(values[5 : 5 + query_length])
    subject = list(values[5 + query_length :])
    if any(not (65 <= value <= 90 or 97 <= value <= 122 or value == 45) for value in query + subject):
        return None
    return query_length, subject_length, match_score, mismatch_score, query, subject


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    parsed = _parse(values, input_length)
    if parsed is None:
        return INVALID_RESULT
    query_length, subject_length, match_score, mismatch_score, query, subject = parsed
    gap_score = values[4]
    scores = [[0] * (subject_length + 1) for _ in range(query_length + 1)]
    maximum = 0
    for row in range(1, query_length + 1):
        for column in range(1, subject_length + 1):
            pair_score = match_score if query[row - 1] == subject[column - 1] else mismatch_score
            value = max(
                0,
                scores[row - 1][column - 1] + pair_score,
                scores[row - 1][column] + gap_score,
                scores[row][column - 1] + gap_score,
            )
            scores[row][column] = value
            if value > maximum:
                maximum = value
    return maximum
