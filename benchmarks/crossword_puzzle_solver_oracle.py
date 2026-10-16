"""Reference behavior for TheAlgorithms/Python crossword backtracker."""

from __future__ import annotations

import struct

MAX_DIMENSION = 8
MAX_WORDS = 8
MAX_WORD_LENGTH = 8
MAX_INPUT_LENGTH = 3 + MAX_DIMENSION * MAX_DIMENSION + MAX_WORDS * (MAX_WORD_LENGTH + 1)


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    rows, cols, word_count = values[:3]
    if not (1 <= rows <= MAX_DIMENSION and 1 <= cols <= MAX_DIMENSION
            and 0 <= word_count <= MAX_WORDS
            and len(values) >= 3 + rows * cols):
        return -1, b""

    grid = list(values[3:3 + rows * cols])
    if any(value != 0 and value != -1 and not 65 <= value <= 90 for value in grid):
        return -1, b""

    words: list[list[int]] = []
    position = 3 + rows * cols
    for _ in range(word_count):
        if position >= len(values):
            return -1, b""
        word_length = values[position]
        position += 1
        if not 1 <= word_length <= MAX_WORD_LENGTH or position + word_length > len(values):
            return -1, b""
        word = list(values[position:position + word_length])
        if any(not 65 <= letter <= 90 for letter in word):
            return -1, b""
        words.append(word)
        position += word_length
    if position != len(values):
        return -1, b""

    # Python's sort is stable, so equal-length words retain input order.
    order = sorted(range(word_count), key=lambda index: len(words[index]), reverse=True)

    def search(depth: int) -> bool:
        if depth == word_count:
            return True
        word = words[order[depth]]
        for row in range(rows):
            for col in range(cols):
                for vertical in (True, False):
                    if vertical and row + len(word) > rows:
                        continue
                    if not vertical and col + len(word) > cols:
                        continue
                    cells = [((row + offset) * cols + col) if vertical
                             else (row * cols + col + offset)
                             for offset in range(len(word))]
                    if any(grid[cell] not in (0, letter)
                           for cell, letter in zip(cells, word)):
                        continue
                    newly_filled = [grid[cell] == 0 for cell in cells]
                    for cell, letter in zip(cells, word):
                        grid[cell] = letter
                    if search(depth + 1):
                        return True
                    for cell, was_empty in zip(cells, newly_filled):
                        if was_empty:
                            grid[cell] = 0
        return False

    solved = search(0)
    packed = [int(solved), *grid]
    output = struct.pack("<" + "q" * len(packed), *packed)
    return len(output), output
