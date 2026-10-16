"""Reference behavior for the pinned Java blank-cell crossword backtracker."""

from __future__ import annotations

import struct

MAX_DIMENSION = 8
MAX_WORDS = 8
MAX_WORD_LENGTH = 8


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return -1, b""
    rows, cols, word_count = values[:3]
    if not (1 <= rows <= MAX_DIMENSION and 1 <= cols <= MAX_DIMENSION
            and 0 <= word_count <= MAX_WORDS
            and len(values) >= 3 + rows * cols):
        return -1, b""
    position = 3
    grid = list(values[position:position + rows * cols])
    position += rows * cols
    if any(v != 0 and v != -1 and not 65 <= v <= 90 for v in grid):
        return -1, b""
    words: list[list[int]] = []
    for _ in range(word_count):
        if position >= len(values):
            return -1, b""
        length = values[position]
        position += 1
        if not 1 <= length <= MAX_WORD_LENGTH or position + length > len(values):
            return -1, b""
        word = values[position:position + length]
        if any(not 65 <= c <= 90 for c in word):
            return -1, b""
        if word in words:
            return -1, b""
        words.append(word)
        position += length
    if position != len(values):
        return -1, b""

    remaining = list(range(word_count))

    def search() -> bool:
        try:
            start = grid.index(0)
        except ValueError:
            return True
        row, col = divmod(start, cols)
        for word_index in list(remaining):
            word = words[word_index]
            for vertical in (True, False):
                if vertical:
                    if row + len(word) > rows:
                        continue
                    positions = [(row + i) * cols + col for i in range(len(word))]
                else:
                    if col + len(word) > cols:
                        continue
                    positions = [row * cols + col + i for i in range(len(word))]
                if any(grid[p] != 0 for p in positions):
                    continue
                for p, letter in zip(positions, word):
                    grid[p] = letter
                remaining.remove(word_index)
                if search():
                    return True
                remaining.append(word_index)
                for p in positions:
                    grid[p] = 0
        return False

    solved = search()
    packed = [int(solved), *grid]
    output = struct.pack("<" + "q" * len(packed), *packed)
    return len(output), output
