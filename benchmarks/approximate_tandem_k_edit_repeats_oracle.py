"""Primary exhaustive partition oracle for bounded K-edit repeats."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 12
MAX_INPUT_LENGTH = 14
MAX_OUTPUT_BYTES = 1592


def _parse(values: Sequence[int] | None) -> tuple[int, int, list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, budget = values[0], values[1]
    text = list(values[2:])
    if (not 2 <= n <= MAX_TEXT or not 0 <= budget <= 4 or len(values) != n + 2
            or any(not 0 <= symbol <= 3 for symbol in text)):
        return None
    return n, budget, text


def _edit_distance(text: Sequence[int], a: int, a_length: int, b: int, b_length: int) -> int:
    row = list(range(b_length + 1))
    for i in range(1, a_length + 1):
        diagonal = row[0]
        row[0] = i
        for j in range(1, b_length + 1):
            above = row[j]
            row[j] = min(above + 1, row[j - 1] + 1,
                         diagonal + (text[a + i - 1] != text[b + j - 1]))
            diagonal = above
    return row[b_length]


def _factor_minimum(text: Sequence[int], start: int, length: int) -> int:
    best = MAX_TEXT * MAX_TEXT
    for prefix_length in range(length + 1):
        for suffix_length in range(length - prefix_length + 1):
            middle_length = length - prefix_length - suffix_length
            if middle_length < 2:
                continue
            # Every internal cut bit gives one partition into nonempty w_i pieces.
            for cuts in range(1, 1 << (middle_length - 1)):
                piece_starts: list[int] = []
                piece_lengths: list[int] = []
                previous = 0
                for cut in range(1, middle_length):
                    if cuts & (1 << (cut - 1)):
                        piece_starts.append(start + prefix_length + previous)
                        piece_lengths.append(cut - previous)
                        previous = cut
                piece_starts.append(start + prefix_length + previous)
                piece_lengths.append(middle_length - previous)

                left_cost = min(
                    _edit_distance(text, start, prefix_length,
                                   piece_starts[0] + piece_lengths[0] - fragment, fragment)
                    for fragment in range(piece_lengths[0] + 1))
                last = len(piece_starts) - 1
                right_cost = min(
                    _edit_distance(text, piece_starts[last], fragment,
                                   start + length - suffix_length, suffix_length)
                    for fragment in range(piece_lengths[last] + 1))
                internal_cost = sum(
                    _edit_distance(text, piece_starts[i], piece_lengths[i],
                                   piece_starts[i + 1], piece_lengths[i + 1])
                    for i in range(last))
                best = min(best, left_cost + internal_cost + right_cost)
    return best


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, budget, text = parsed
    records = [(start, length, cost)
               for start in range(n)
               for length in range(2, n - start + 1)
               if (cost := _factor_minimum(text, start, length)) <= budget]
    words = (len(records), *(word for record in records for word in record))
    output = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
