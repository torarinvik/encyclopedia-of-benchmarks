"""Independent reverse-ranking reference built from legal unique arrangements."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_POSITIONS = 960
MAX_VALID_INPUT_LENGTH = 961
MAX_PARSEABLE_INPUT_LENGTH = 962
MAX_OUTPUT_BYTES = MAX_POSITIONS * 8
WORKSPACE_BYTES = 192
SYMBOLS = ("B", "K", "N", "Q", "R")


def _identifier_for(board: tuple[str, ...]) -> int | None:
    bishops = [file for file, piece in enumerate(board) if piece == "B"]
    if len(bishops) != 2 or bishops[0] % 2 == bishops[1] % 2:
        return None
    rooks = [file for file, piece in enumerate(board) if piece == "R"]
    king = board.index("K")
    if not rooks[0] < king < rooks[1]:
        return None

    odd_bishop = next(file for file in bishops if file % 2 == 1)
    even_bishop = next(file for file in bishops if file % 2 == 0)
    bishop_code = (odd_bishop - 1) // 2 + 4 * (even_bishop // 2)
    six_files = [file for file in range(8) if file not in bishops]
    queen_code = six_files.index(board.index("Q"))
    five_files = [file for file in six_files if file != board.index("Q")]
    knight_files = [file for file, piece in enumerate(board) if piece == "N"]
    first, second = sorted(five_files.index(file) for file in knight_files)
    knight_code = sum(4 - earlier for earlier in range(first)) + second - first - 1
    return bishop_code + 16 * queen_code + 96 * knight_code


def _position_table() -> tuple[bytes, ...]:
    table: list[bytes | None] = [None] * MAX_POSITIONS
    counts = {"B": 2, "K": 1, "N": 2, "Q": 1, "R": 2}
    prefix: list[str] = []

    def visit() -> None:
        if len(prefix) == 8:
            board = tuple(prefix)
            identifier = _identifier_for(board)
            if identifier is not None:
                if table[identifier] is not None:
                    raise RuntimeError("reverse ranking assigned duplicate identifiers")
                table[identifier] = "".join(board).encode("ascii")
            return
        for symbol in SYMBOLS:
            if counts[symbol] == 0:
                continue
            counts[symbol] -= 1
            prefix.append(symbol)
            visit()
            prefix.pop()
            counts[symbol] += 1

    visit()
    if any(position is None for position in table):
        raise RuntimeError("reverse ranking did not cover all 960 identifiers")
    return tuple(position if position is not None else b"" for position in table)


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
    table = _position_table()
    output = b"".join(table[identifier] for identifier in identifiers)
    return required, output
