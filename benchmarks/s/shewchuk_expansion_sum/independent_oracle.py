"""Independent exact-integer oracle for the bounded dyadic sum contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TERMS = 16
MAX_LENGTH = 34
MAX_MANTISSA = 1 << 24
INVALID_RESULT = -1
OUTPUT_OFFSET = (1 << 58) + 1


def _valid_frame(words: Sequence[int] | None, null_input: bool,
                 length: int | None) -> bool:
    if (type(null_input) is not bool or null_input
            or not isinstance(words, (tuple, list))
            or not 1 <= len(words) <= MAX_LENGTH):
        return False
    if any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
           for item in words):
        return False
    if length is None:
        length = len(words)
    if type(length) is not int or length != len(words):
        return False
    n = words[0]
    if n < 0 or n > MAX_TERMS or length != 1 + 2 * n:
        return False
    return all(-MAX_MANTISSA <= words[1 + 2 * i] <= MAX_MANTISSA
               and -30 <= words[2 + 2 * i] <= 0 for i in range(n))


def expected_result(words: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if not _valid_frame(words, input_is_null, input_length):
        return INVALID_RESULT
    assert words is not None
    return OUTPUT_OFFSET + sum(words[1 + 2 * i] * (1 << (words[2 + 2 * i] + 30))
                               for i in range(words[0]))


def verify_candidate(words: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    expected = expected_result(words, input_is_null, input_length)
    return type(result) is int and result == expected
