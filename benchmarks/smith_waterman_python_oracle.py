"""Oracle for the pinned Python Smith-Waterman matrix and traceback APIs."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SEQUENCE_LENGTH = 16
MAX_VALID_INPUT_LENGTH = 5 + 2 * MAX_SEQUENCE_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 1233
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_length: int | None = None) -> tuple[int, int, int, int, int, str, str] | None:
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
    if not 1 <= match_score <= 5 or not -5 <= mismatch_score <= -1 or not -5 <= gap_score <= -1:
        return None
    if len(values) != 5 + query_length + subject_length:
        return None
    encoded = values[5:]
    if any(not (65 <= value <= 90 or 97 <= value <= 122 or value == 45) for value in encoded):
        return None
    letters = bytes(encoded).decode("ascii").upper()
    return query_length, subject_length, match_score, mismatch_score, gap_score, letters[:query_length], letters[query_length:]


def _pair_score(left: str, right: str, match: int, mismatch: int, gap: int) -> int:
    if left == "-" or right == "-":
        return gap
    return match if left == right else mismatch


def _matrix(query: str, subject: str, match: int, mismatch: int, gap: int) -> list[list[int]]:
    rows, columns = len(query) + 1, len(subject) + 1
    score = [[0] * columns for _ in range(rows)]
    for row in range(1, rows):
        for column in range(1, columns):
            diagonal = score[row - 1][column - 1] + _pair_score(
                query[row - 1], subject[column - 1], match, mismatch, gap
            )
            delete = score[row - 1][column] + gap
            insert = score[row][column - 1] + gap
            score[row][column] = max(0, diagonal, delete, insert)
    return score


def _python_traceback(score: list[list[int]], query: str, subject: str) -> bytes:
    maximum = float("-inf")
    i_max = j_max = 0
    for row, values in enumerate(score):
        for column, value in enumerate(values):
            if value > maximum:
                maximum = value
                i_max, j_max = row, column
    i, j = i_max, j_max
    if i == 0 or j == 0:
        return b""
    align_query = ""
    align_subject = ""
    default_gap = -2
    while i > 0 and j > 0:
        diagonal_score = score[i - 1][j - 1] + _pair_score(query[i - 1], subject[j - 1], 1, -1, default_gap)
        if score[i][j] == diagonal_score:
            align_query = query[i - 1] + align_query
            align_subject = subject[j - 1] + align_subject
            i -= 1
            j -= 1
        elif score[i][j] == score[i - 1][j] + default_gap:
            align_query = query[i - 1] + align_query
            align_subject = "-" + align_subject
            i -= 1
        else:
            align_query = "-" + align_query
            align_subject = subject[j - 1] + align_subject
            j -= 1
    return f"{align_query}\n{align_subject}".encode("ascii")


def _encode(score: list[list[int]], alignment: bytes) -> bytes:
    rows, columns = len(score), len(score[0])
    output = bytearray(rows.to_bytes(4, "little") + columns.to_bytes(4, "little"))
    for row in score:
        for value in row:
            output.extend(value.to_bytes(4, "little", signed=True))
    output.extend(len(alignment).to_bytes(4, "little"))
    output.extend(alignment)
    return bytes(output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool or (
        capacity is not None and (type(capacity) is not int or capacity < 0)
    ):
        return INVALID_RESULT, b""
    query_length, subject_length, match, mismatch, gap, query, subject = parsed
    score = _matrix(query, subject, match, mismatch, gap)
    payload = _encode(score, _python_traceback(score, query, subject))
    if len(payload) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return OUTPUT_ERROR, b""
    return len(payload), payload
