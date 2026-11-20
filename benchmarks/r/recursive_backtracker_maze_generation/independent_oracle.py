"""Recursive reference that records passages before deriving wall masks."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_CELLS = 64
MAX_PARSEABLE_INPUT_LENGTH = 68
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 1024
MOVES = ((-1, 0), (0, 1), (1, 0), (0, -1))
WALL = (1, 2, 4, 8)
REVERSE_WALL = (4, 8, 1, 2)


def _read_frame(values: Sequence[int], is_null: bool,
                length: int) -> tuple[int, int, int, list[int]] | None:
    if (not isinstance(values, (tuple, list)) or type(is_null) is not bool
            or is_null or type(length) is not int or length != len(values)
            or not 4 <= length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    height, width, origin, tape_size = values[0], values[1], values[2], values[3]
    if height <= 0 or width <= 0 or height > MAX_CELLS or width > MAX_CELLS:
        return None
    total = height * width
    if total > MAX_CELLS or origin < 0 or origin >= total:
        return None
    if tape_size < 0 or tape_size != total - 1 or length != tape_size + 4:
        return None
    tape = list(values[4:])
    if any(value < 0 or value > 3 for value in tape):
        return None
    return height, width, origin, tape


def _recurse(height: int, width: int, origin: int,
             tape: list[int]) -> list[tuple[int, int]] | None:
    seen = {origin}
    passages: list[tuple[int, int]] = []
    offset = 0

    def visit(cell: int) -> bool:
        nonlocal offset
        row, col = divmod(cell, width)
        candidates: list[tuple[int, int]] = []
        for move, (dr, dc) in enumerate(MOVES):
            rr, cc = row + dr, col + dc
            if 0 <= rr < height and 0 <= cc < width:
                neighbor = rr * width + cc
                if neighbor not in seen:
                    candidates.append((neighbor, move))
        if not candidates:
            return True
        if offset >= len(tape):
            return False
        rank = tape[offset]
        if rank >= len(candidates):
            return False
        offset += 1
        neighbor, _ = candidates[rank]
        seen.add(neighbor)
        passages.append((cell, neighbor))
        return visit(neighbor) and _resume(cell)

    def _resume(cell: int) -> bool:
        # A resumed frame chooses again from the remaining unvisited neighbors.
        return visit(cell)

    if not visit(origin) or offset != len(tape) or len(seen) != height * width:
        return None
    return passages


def _wall_bytes(height: int, width: int,
                passages: list[tuple[int, int]]) -> bytes:
    masks = [15] * (height * width)
    for source, target in passages:
        sr, sc = divmod(source, width)
        tr, tc = divmod(target, width)
        if tr == sr - 1:
            direction = 0
        elif tc == sc + 1:
            direction = 1
        elif tr == sr + 1:
            direction = 2
        else:
            direction = 3
        masks[source] &= ~WALL[direction]
        masks[target] &= ~REVERSE_WALL[direction]
    return bytes(masks)


def expected_output(values: Sequence[int], capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT, b""
    parsed = _read_frame(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, b""
    height, width, origin, tape = parsed
    passages = _recurse(height, width, origin, tape)
    if passages is None:
        return INVALID_RESULT, b""
    result = _wall_bytes(height, width, passages)
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
