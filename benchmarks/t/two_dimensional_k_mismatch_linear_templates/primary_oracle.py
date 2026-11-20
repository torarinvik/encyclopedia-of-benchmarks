"""Two-witness linear-template filter for 2D one-mismatch matching."""
from __future__ import annotations

import struct
from collections import defaultdict
from collections.abc import Sequence

MAX_SIDE = 12
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_MATCHES = (MAX_SIDE - 3 + 1) ** 2
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_MATCHES)
WORKSPACE_BYTES = 8192


def _parse(values: Sequence[int]):
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 3 <= m <= n <= MAX_SIDE or len(values) != 2 + n * n + m * m:
        return None
    text = tuple(values[2:2 + n * n])
    pattern = tuple(values[2 + n * n:])
    if any(value < 0 or value > 3 for value in text + pattern):
        return None
    return n, m, text, pattern


def _parameters(m: int) -> tuple[int, int]:
    q = 1
    capacity = 4
    while capacity < m * m:
        q += 1
        capacity *= 4
    return q, m // q


def _sample(array: Sequence[int], side: int, row: int, column: int,
            q: int, stride: int) -> int:
    code = 0
    for step in range(q):
        code = 4 * code + array[row * side + column + step * stride]
    return code


def _matches(n: int, m: int, text: Sequence[int],
             pattern: Sequence[int]) -> list[tuple[int, int]]:
    q, stride = _parameters(m)
    final_offset = (q - 1) * stride
    # Each key points to all pattern row/residue addresses with that sample.
    addresses: dict[int, list[tuple[int, int]]] = defaultdict(list)
    for row in range(m):
        for residue in range(stride):
            code = _sample(pattern, m, row, residue, q, stride)
            addresses[code].append((row, residue))

    tested = [False] * (n * n)
    found: list[tuple[int, int]] = []
    for text_row in range(n):
        # Two consecutive periodic test-row classes give u=2 witnesses in
        # every m-row candidate window.
        if text_row % m < m - 2:
            continue
        for text_column in range(0, n - final_offset, stride):
            code = _sample(text, n, text_row, text_column, q, stride)
            for pattern_row, residue in addresses.get(code, ()):
                row = text_row - pattern_row
                column = text_column - residue
                if not (0 <= row <= n - m and 0 <= column <= n - m):
                    continue
                slot = row * n + column
                if tested[slot]:
                    continue
                # p=1: the first positive witness sends the candidate to
                # verification. Stop when k+1=2 mismatches are observed.
                tested[slot] = True
                mismatches = 0
                for dr in range(m):
                    for dc in range(m):
                        if text[(row + dr) * n + column + dc] != pattern[dr * m + dc]:
                            mismatches += 1
                            if mismatches == 2:
                                break
                    if mismatches == 2:
                        break
                if mismatches <= 1:
                    found.append((row, column))
    found.sort()
    return found


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
    words = [len(matches), *(coordinate for pair in matches for coordinate in pair)]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
