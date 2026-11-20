"""Myers furthest-reaching-path oracle for a bounded insert/delete script."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SEQUENCE_LENGTH = 16
MAX_INPUT_LENGTH = 2 + 2 * MAX_SEQUENCE_LENGTH
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES = 3 * MAX_SEQUENCE_LENGTH
MAX_DISTANCE = 2 * MAX_SEQUENCE_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2

# Operation records are (tag, byte): match=0, delete=1, insert=2.
MATCH = 0
DELETE = 1
INSERT = 2


def _equal_snake(first: Sequence[int], second: Sequence[int], x: int, y: int) -> tuple[int, int]:
    while x < len(first) and y < len(second) and first[x] == second[y]:
        x += 1
        y += 1
    return x, y


def _myers_script(first: Sequence[int], second: Sequence[int]) -> bytes:
    """Run the paper's O((n+m)D) wavefront and backtrack its pinned path."""
    n, m = len(first), len(second)
    max_d = n + m
    offset = max_d + 1
    frontier = [-1] * (2 * max_d + 3)
    frontier[offset + 1] = 0
    snapshots: list[list[int]] = []
    final_d = -1
    final_k = 0

    for distance in range(max_d + 1):
        row = [-1] * len(frontier)
        for diagonal in range(-distance, distance + 1, 2):
            slot = offset + diagonal
            if diagonal == -distance or (
                diagonal != distance and frontier[slot - 1] < frontier[slot + 1]
            ):
                x = frontier[slot + 1]
            else:
                x = frontier[slot - 1] + 1
            y = x - diagonal
            x, y = _equal_snake(first, second, x, y)
            frontier[slot] = x
            row[slot] = x
            if x >= n and y >= m:
                final_d = distance
                final_k = diagonal
                snapshots.append(row)
                break
        else:
            snapshots.append(row)
            continue
        break

    if final_d < 0:
        return b""

    reverse_path: list[tuple[int, int]] = []
    x, y, diagonal = n, m, final_k
    for distance in range(final_d, 0, -1):
        previous = snapshots[distance - 1]
        slot = offset + diagonal
        if diagonal == -distance or (
            diagonal != distance and previous[slot - 1] < previous[slot + 1]
        ):
            previous_diagonal = diagonal + 1
            previous_x = previous[offset + previous_diagonal]
            previous_y = previous_x - previous_diagonal
            snake_x, snake_y = previous_x, previous_y + 1
            while x > snake_x and y > snake_y:
                reverse_path.append((MATCH, 0))
                x -= 1
                y -= 1
            reverse_path.append((INSERT, second[previous_y]))
        else:
            previous_diagonal = diagonal - 1
            previous_x = previous[offset + previous_diagonal]
            previous_y = previous_x - previous_diagonal
            snake_x, snake_y = previous_x + 1, previous_y
            while x > snake_x and y > snake_y:
                reverse_path.append((MATCH, 0))
                x -= 1
                y -= 1
            reverse_path.append((DELETE, 0))
        x, y, diagonal = previous_x, previous_y, previous_diagonal

    prefix_matches = snapshots[0][offset]
    while prefix_matches > 0:
        reverse_path.append((MATCH, 0))
        prefix_matches -= 1
    reverse_path.reverse()

    encoded = bytearray()
    for operation, symbol in reverse_path:
        encoded.append(operation)
        if operation == INSERT:
            encoded.append(symbol)
    return bytes(encoded)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_LENGTH:
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


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and the replayable minimum insert/delete instruction stream."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_PARSEABLE_LENGTH)):
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    first, second = parsed
    script = _myers_script(first, second)
    if output_is_null or capacity is not None and capacity < len(script):
        return OUTPUT_ERROR, b""
    return len(script), script
