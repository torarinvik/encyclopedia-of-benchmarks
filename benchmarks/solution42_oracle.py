"""Oracle for the pinned Project Euler 42 word-file counter."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 16_384
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
ASCII_MAX = 127
TRIANGULAR_VALUES = frozenset(n * (n + 1) // 2 for n in range(1, 101))


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    """Count triangular word scores in the first ASCII line only.

    The adapter supplies the bytes of the source's ``words.txt`` as one i64
    array element per byte. The source calls ``readline()``, strips CR/LF from
    that line, splits on commas, strips quote characters at each token's ends,
    and scores every remaining character as ``ord(character) - 64``.
    """
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH
    ):
        return INVALID_RESULT
    if input_is_null:
        if values not in (None, [], ()) or input_length is None:
            return INVALID_RESULT
        return 0 if input_length == 0 else INVALID_RESULT
    if values is None:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if any(
        type(value) is not int
        or not I64_MIN <= value <= I64_MAX
        or not 0 <= value <= ASCII_MAX
        for value in values
    ):
        return INVALID_RESULT

    raw = bytes(values)
    separator = next((index for index, byte in enumerate(raw) if byte in (10, 13)), len(raw))
    first_line = raw[:separator]
    words = (word.strip(b'"') for word in first_line.split(b","))
    return sum(sum(character - 64 for character in word) in TRIANGULAR_VALUES
               for word in words)
