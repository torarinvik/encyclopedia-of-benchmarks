"""Three-dimensional Bird–Baker slice-label reduction with depth KMP."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_DIMENSION = 5
MAX_PATTERN_DIMENSION = 4
MAX_VALID_INPUT_LENGTH = 6 + MAX_DIMENSION ** 3 + MAX_PATTERN_DIMENSION ** 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_MATCHES = MAX_DIMENSION ** 3
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_MATCHES)
WORKSPACE_BYTES = 8192


def _parse(values: Sequence[int]):
    if len(values) < 7 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    rows, columns, depths, pattern_rows, pattern_columns, pattern_depths = values[:6]
    if (not 1 <= rows <= MAX_DIMENSION or not 1 <= columns <= MAX_DIMENSION
            or not 1 <= depths <= MAX_DIMENSION
            or not 1 <= pattern_rows <= MAX_PATTERN_DIMENSION
            or not 1 <= pattern_columns <= MAX_PATTERN_DIMENSION
            or not 1 <= pattern_depths <= MAX_PATTERN_DIMENSION
            or pattern_rows > rows or pattern_columns > columns or pattern_depths > depths):
        return None
    text_size = rows * columns * depths
    pattern_size = pattern_rows * pattern_columns * pattern_depths
    if len(values) != 6 + text_size + pattern_size:
        return None
    text = tuple(values[6:6 + text_size])
    pattern = tuple(values[6 + text_size:])
    if any(not 0 <= value <= 3 for value in (*text, *pattern)):
        return None
    return rows, columns, depths, pattern_rows, pattern_columns, pattern_depths, text, pattern


def _prefix(pattern: Sequence[object]) -> list[int]:
    prefix = [0] * len(pattern)
    for index in range(1, len(pattern)):
        matched = prefix[index - 1]
        while matched and pattern[index] != pattern[matched]:
            matched = prefix[matched - 1]
        if pattern[index] == pattern[matched]:
            matched += 1
        prefix[index] = matched
    return prefix


def _match_2d(text: Sequence[Sequence[int]], pattern: Sequence[Sequence[int]]) -> list[tuple[int, int]]:
    rows = len(text)
    columns = len(text[0])
    pattern_rows = len(pattern)
    pattern_columns = len(pattern[0])
    starts = columns - pattern_columns + 1
    marks = [[[False] * pattern_rows for _ in range(starts)] for _ in range(rows)]
    for row in range(rows):
        for column in range(starts):
            segment = text[row][column:column + pattern_columns]
            for pattern_row in range(pattern_rows):
                marks[row][column][pattern_row] = segment == pattern[pattern_row]

    prefix = _prefix(pattern)
    matches: list[tuple[int, int]] = []
    for column in range(starts):
        matched = 0
        for row in range(rows):
            while matched and not marks[row][column][matched]:
                matched = prefix[matched - 1]
            if marks[row][column][matched]:
                matched += 1
            if matched == pattern_rows:
                matches.append((row + 1 - pattern_rows, column))
                matched = prefix[matched - 1]
    return matches


def _three_dimensional_matches(rows: int, columns: int, depths: int,
                               pattern_rows: int, pattern_columns: int,
                               pattern_depths: int, text_values: Sequence[int],
                               pattern_values: Sequence[int]) -> list[tuple[int, int, int]]:
    text_planes = [
        [tuple(text_values[(depth * rows + row) * columns + column
                           :(depth * rows + row) * columns + column + columns])
         for row in range(rows)]
        for depth in range(depths)
    ]
    pattern_planes = [
        [tuple(pattern_values[(depth * pattern_rows + row) * pattern_columns + column
                              :(depth * pattern_rows + row) * pattern_columns + column + pattern_columns])
         for row in range(pattern_rows)]
        for depth in range(pattern_depths)
    ]

    unique_planes: list[tuple[tuple[int, ...], ...]] = []
    plane_ids: list[int] = []
    plane_lookup: dict[tuple[tuple[int, ...], ...], int] = {}
    for plane in pattern_planes:
        key = tuple(plane)
        if key not in plane_lookup:
            plane_lookup[key] = len(unique_planes)
            unique_planes.append(key)
        plane_ids.append(plane_lookup[key])

    row_starts = rows - pattern_rows + 1
    column_starts = columns - pattern_columns + 1
    tokens = [[[-1] * column_starts for _ in range(row_starts)] for _ in range(depths)]
    for depth, text_plane in enumerate(text_planes):
        for plane_id, pattern_plane in enumerate(unique_planes):
            for row, column in _match_2d(text_plane, pattern_plane):
                tokens[depth][row][column] = plane_id

    prefix = _prefix(plane_ids)
    matches: list[tuple[int, int, int]] = []
    for row in range(row_starts):
        for column in range(column_starts):
            matched = 0
            for depth in range(depths):
                token = tokens[depth][row][column]
                while matched and token != plane_ids[matched]:
                    matched = prefix[matched - 1]
                if token == plane_ids[matched]:
                    matched += 1
                if matched == pattern_depths:
                    matches.append((row, column, depth + 1 - pattern_depths))
                    matched = prefix[matched - 1]
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
    rows, columns, depths, pattern_rows, pattern_columns, pattern_depths, text, pattern = parsed
    matches = _three_dimensional_matches(
        rows, columns, depths, pattern_rows, pattern_columns, pattern_depths, text, pattern)
    words = [len(matches), *(coordinate for match in matches for coordinate in match)]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
