"""Direct substring oracle for the online distinct-palindrome eertree benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 128
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
ALPHABET_SIZE = 26
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = [
    {
        "organization": "Library Checker",
        "title": "Eertree",
        "url": "https://judge.yosupo.jp/problem/eertree",
        "role": "problem_taxonomy",
    },
    {
        "organization": "Mikhail Rubinchik and Arseny M. Shur",
        "title": "EERTREE: An Efficient Data Structure for Processing Palindromes in Strings",
        "url": "https://arxiv.org/abs/1506.04862",
        "role": "algorithm_description",
    },
]


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Compute the prefix checksum by enumerating and comparing substrings."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or len(values) < 1 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or len(values) != text_length + 1:
        return INVALID_RESULT
    letters = values[1:]
    if any(letter < 0 or letter >= ALPHABET_SIZE for letter in letters):
        return INVALID_RESULT

    text = "".join(chr(ord("a") + letter) for letter in letters)
    checksum = 0
    for end in range(1, text_length + 1):
        prefix = text[:end]
        palindromes: set[str] = set()
        for start in range(end):
            for stop in range(start + 1, end + 1):
                substring = prefix[start:stop]
                if substring == substring[::-1]:
                    palindromes.add(substring)
        checksum += end * len(palindromes)
    return checksum
