"""Full-table insert/delete DP and script replay verifier."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SEQUENCE_LENGTH = 16
MAX_PARSEABLE_LENGTH = 2 + 2 * MAX_SEQUENCE_LENGTH + 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MATCH = 0
DELETE = 1
INSERT = 2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m = values[:2]
    if not 0 <= n <= MAX_SEQUENCE_LENGTH or not 0 <= m <= MAX_SEQUENCE_LENGTH:
        return None
    if len(values) != 2 + n + m:
        return None
    first = tuple(values[2:2 + n])
    second = tuple(values[2 + n:])
    if any(not 0 <= symbol <= 255 for symbol in first + second):
        return None
    return first, second


def _table(first: Sequence[int], second: Sequence[int]) -> list[list[int]]:
    """Compute every prefix-pair cost with a full Wagner–Fischer table."""
    rows = len(first) + 1
    columns = len(second) + 1
    table = [[0] * columns for _ in range(rows)]
    for i in range(rows):
        table[i][0] = i
    for j in range(columns):
        table[0][j] = j
    for i in range(1, rows):
        for j in range(1, columns):
            if first[i - 1] == second[j - 1]:
                table[i][j] = table[i - 1][j - 1]
            else:
                table[i][j] = min(table[i - 1][j] + 1, table[i][j - 1] + 1)
    return table


def _traceback_script(first: Sequence[int], second: Sequence[int],
                      table: list[list[int]]) -> bytes:
    """Return one optimal witness, preferring deletion on local DP ties."""
    i, j = len(first), len(second)
    reverse_path: list[tuple[int, int]] = []
    while i > 0 or j > 0:
        if i > 0 and j > 0 and first[i - 1] == second[j - 1]:
            reverse_path.append((MATCH, 0))
            i -= 1
            j -= 1
        elif i > 0 and (j == 0 or table[i - 1][j] <= table[i][j - 1]):
            reverse_path.append((DELETE, 0))
            i -= 1
        else:
            reverse_path.append((INSERT, second[j - 1]))
            j -= 1
    reverse_path.reverse()
    encoded = bytearray()
    for operation, symbol in reverse_path:
        encoded.append(operation)
        if operation == INSERT:
            encoded.append(symbol)
    return bytes(encoded)


def reference_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return an independently tied O(n*m) optimal witness for comparison."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_PARSEABLE_LENGTH)):
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    first, second = parsed
    table = _table(first, second)
    script = _traceback_script(first, second, table)
    if output_is_null or capacity is not None and capacity < len(script):
        return OUTPUT_ERROR, b""
    return len(script), script


def verify_output(
    values: Sequence[int] | None,
    result: int,
    payload: bytes,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> bool:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == INVALID_RESULT and payload == b""
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return result == INVALID_RESULT and payload == b""
    if output_is_null:
        return result == OUTPUT_ERROR and payload == b""

    first, second = parsed
    table = _table(first, second)
    distance = table[-1][-1]
    lcs_length = (len(first) + len(second) - distance) // 2
    required_bytes = len(first) + 2 * len(second) - 2 * lcs_length
    if capacity is not None and capacity < required_bytes:
        return result == OUTPUT_ERROR and payload == b""
    if result != len(payload) or len(payload) != required_bytes:
        return False

    a_index = 0
    b_index = 0
    edits = 0
    at = 0
    while at < len(payload):
        operation = payload[at]
        at += 1
        if operation == MATCH:
            if a_index >= len(first) or b_index >= len(second) or first[a_index] != second[b_index]:
                return False
            a_index += 1
            b_index += 1
        elif operation == DELETE:
            if a_index >= len(first):
                return False
            a_index += 1
            edits += 1
        elif operation == INSERT:
            if at >= len(payload) or b_index >= len(second) or payload[at] != second[b_index]:
                return False
            at += 1
            b_index += 1
            edits += 1
        else:
            return False
    return a_index == len(first) and b_index == len(second) and edits == distance
