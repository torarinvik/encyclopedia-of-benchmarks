"""Fixed-linear-template filter for exact 2D pattern occurrences."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_SIDE = 12
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_SAMPLES = MAX_CELLS
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_MATCHES = MAX_CELLS
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_MATCHES)
WORKSPACE_BYTES = 8192


def _parse(values: Sequence[int]):
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 1 <= m <= n <= MAX_SIDE or len(values) != 2 + n * n + m * m:
        return None
    text = tuple(values[2:2 + n * n])
    pattern = tuple(values[2 + n * n:])
    if any(value < 0 or value >= 4 for value in text + pattern):
        return None
    return n, m, text, pattern


def _sample_parameters(m: int) -> tuple[int, int]:
    q = 1
    alphabet_capacity = 4
    while alphabet_capacity < m * m:
        q += 1
        alphabet_capacity *= 4
    return q, m // q


def _sample_code(array: Sequence[int], side: int, row: int, column: int,
                 q: int, stride: int) -> int:
    code = 0
    for offset in range(q):
        code = 4 * code + array[row * side + column + offset * stride]
    return code


def _matches(n: int, m: int, text: Sequence[int], pattern: Sequence[int]) -> list[tuple[int, int]]:
    q, stride = _sample_parameters(m)
    heads = [-1] * 256
    next_address = [-1] * MAX_SAMPLES
    address_row = [0] * MAX_SAMPLES
    address_column = [0] * MAX_SAMPLES
    address_count = 0

    # The paper's overlapping linear templates use every pattern row and
    # each horizontal residue below the text-grid spacing.
    for row in range(m):
        for residue in range(stride):
            code = _sample_code(pattern, m, row, residue, q, stride)
            address_row[address_count] = row
            address_column[address_count] = residue
            next_address[address_count] = heads[code]
            heads[code] = address_count
            address_count += 1

    seen = [False] * (n * n)
    matches: list[tuple[int, int]] = []
    final_offset = (q - 1) * stride
    for text_row in range(0, n, m):
        for text_column in range(0, n - final_offset, stride):
            code = _sample_code(text, n, text_row, text_column, q, stride)
            address = heads[code]
            while address >= 0:
                row = text_row - address_row[address]
                column = text_column - address_column[address]
                if (0 <= row <= n - m and 0 <= column <= n - m
                        and not seen[row * n + column]):
                    seen[row * n + column] = True
                    equal = True
                    for pattern_row in range(m):
                        for pattern_column in range(m):
                            if (text[(row + pattern_row) * n + column + pattern_column]
                                    != pattern[pattern_row * m + pattern_column]):
                                equal = False
                                break
                        if not equal:
                            break
                    if equal:
                        matches.append((row, column))
                address = next_address[address]
    matches.sort()
    return matches


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, m, text, pattern = parsed
    matches = _matches(n, m, text, pattern)
    words = [len(matches), *(coordinate for match in matches for coordinate in match)]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
