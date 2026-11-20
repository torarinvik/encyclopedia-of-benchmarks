"""Independent unmatched-count/backtracking reference for parenthesis repair."""

from __future__ import annotations

MAX_TEXT_LENGTH = 16
MAX_PARENTHESIS_COUNT = 8
MAX_INPUT_LENGTH = 17
MAX_PARSEABLE_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 4354
WORKSPACE_BYTES = 8192
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(raw, input_is_null: bool, input_length: int | None):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(raw, (list, tuple)) or not 1 <= len(raw) <= MAX_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in raw):
        return None
    length = len(raw) if input_length is None else input_length
    if type(length) is not int or length != len(raw):
        return None
    n = raw[0]
    if not 0 <= n <= MAX_TEXT_LENGTH or len(raw) != n + 1:
        return None
    data = raw[1:]
    if any(value not in (40, 41) and not 97 <= value <= 122 for value in data):
        return None
    if sum(value in (40, 41) for value in data) > MAX_PARENTHESIS_COUNT:
        return None
    return bytes(data)


def _minimum_deletions(text: bytes) -> tuple[int, int]:
    unmatched_open = 0
    unmatched_close = 0
    for byte in text:
        if byte == 40:
            unmatched_open += 1
        elif byte == 41:
            if unmatched_open:
                unmatched_open -= 1
            else:
                unmatched_close += 1
    return unmatched_open, unmatched_close


def _serialize(results: set[bytes]) -> bytes:
    ordered = sorted(results)
    output = bytearray(len(ordered).to_bytes(2, "little"))
    for candidate in ordered:
        output.append(len(candidate))
        output.extend(candidate)
    return bytes(output)


def _solve(text: bytes) -> bytes:
    remove_open, remove_close = _minimum_deletions(text)
    result_set: set[bytes] = set()
    current = bytearray()

    def visit(index: int, balance: int, left_open: int, left_close: int) -> None:
        if left_open < 0 or left_close < 0:
            return
        if index == len(text):
            if balance == 0 and left_open == 0 and left_close == 0:
                result_set.add(bytes(current))
            return
        byte = text[index]
        if byte == 40:
            if left_open:
                visit(index + 1, balance, left_open - 1, left_close)
            current.append(byte)
            visit(index + 1, balance + 1, left_open, left_close)
            current.pop()
        elif byte == 41:
            if left_close:
                visit(index + 1, balance, left_open, left_close - 1)
            if balance:
                current.append(byte)
                visit(index + 1, balance - 1, left_open, left_close)
                current.pop()
        else:
            current.append(byte)
            visit(index + 1, balance, left_open, left_close)
            current.pop()

    visit(0, 0, remove_open, remove_close)
    return _serialize(result_set)


def expected_output(values: list[int] | tuple[int, ...] | None,
                    output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    text = _parse(values, input_is_null, input_length)
    if text is None:
        return INVALID_RESULT, b""
    if (type(output_capacity) is not int or output_capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    output = _solve(text)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
