"""Direct mixed-radix Scharnagl unranking reference."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_POSITIONS = 960
MAX_VALID_INPUT_LENGTH = 961
MAX_PARSEABLE_INPUT_LENGTH = 962
MAX_OUTPUT_BYTES = MAX_POSITIONS * 8
WORKSPACE_BYTES = 192
KNIGHT_PAIRS = (
    (0, 1), (0, 2), (0, 3), (0, 4), (1, 2),
    (1, 3), (1, 4), (2, 3), (2, 4), (3, 4),
)


def _decode(values: Sequence[int], input_is_null: bool,
            input_length: int) -> tuple[int, ...] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_POSITIONS or input_length != count + 1:
        return None
    identifiers = tuple(values[1:])
    if any(not 0 <= identifier < MAX_POSITIONS for identifier in identifiers):
        return None
    return identifiers


def _unrank(identifier: int) -> bytes:
    remainder = identifier
    odd_bishop_digit = remainder % 4
    remainder //= 4
    even_bishop_digit = remainder % 4
    remainder //= 4
    queen_ordinal = remainder % 6
    knight_pair_ordinal = remainder // 6

    board = [0] * 8
    board[2 * odd_bishop_digit + 1] = ord("B")
    board[2 * even_bishop_digit] = ord("B")
    open_files = [file for file, piece in enumerate(board) if piece == 0]
    board[open_files[queen_ordinal]] = ord("Q")
    five_files = [file for file, piece in enumerate(board) if piece == 0]
    first_knight, second_knight = KNIGHT_PAIRS[knight_pair_ordinal]
    board[five_files[first_knight]] = ord("N")
    board[five_files[second_knight]] = ord("N")
    for file, piece in zip((file for file, value in enumerate(board) if value == 0), b"RKR"):
        board[file] = piece
    return bytes(board)


def expected_output(values: Sequence[int], capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    actual_length = (len(values) if input_length is None and isinstance(values, (tuple, list))
                     else input_length)
    if actual_length is None:
        return INVALID_RESULT, b""
    identifiers = _decode(values, input_is_null, actual_length)
    if identifiers is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    required = len(identifiers) * 8
    if required > 0 and (output_is_null or (capacity is not None and capacity < required)):
        return OUTPUT_ERROR, b""
    output = b"".join(_unrank(identifier) for identifier in identifiers)
    return required, output
