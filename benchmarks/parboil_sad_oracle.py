"""Independent oracle for the bounded Parboil SAD macroblock profile."""

from __future__ import annotations

from typing import Sequence

MAX_INPUT_LENGTH = 128
SEARCH_RANGE = 16
SEARCH_DIMENSION = 2 * SEARCH_RANGE + 1
MAX_POS = SEARCH_DIMENSION * SEARCH_DIMENSION
MAX_RESULT = 497_629_440


def _decode_image(words: Sequence[int]) -> list[int]:
    pixels = [0] * 256
    for y in range(16):
        for group in range(4):
            packed = words[y * 4 + group]
            base_x = group * 4
            row = y * 16
            for lane in range(4):
                pixels[row + base_x + lane] = (packed >> (8 * lane)) & 0xFF
    return pixels


def _valid(values: Sequence[int] | None) -> bool:
    if values is None or len(values) != MAX_INPUT_LENGTH:
        return False
    return all(
        isinstance(value, int)
        and not isinstance(value, bool)
        and 0 <= value <= 0xFFFF_FFFF
        for value in values
    )


def expected_result(values: Sequence[int] | None) -> int:
    """Return the sum of all seven source SAD block types, or -1 if invalid."""
    if not _valid(values):
        return -1

    frame = _decode_image(values[:64])
    reference = _decode_image(values[64:])
    # Enumerate every block at every level directly. This deliberately differs
    # from the ports, which form the larger levels by adding smaller SADs.
    block_shapes = (
        (16, 16),  # type 1: height, width
        (8, 16),   # type 2
        (16, 8),   # type 3
        (8, 8),    # type 4
        (4, 8),    # type 5
        (8, 4),    # type 6
        (4, 4),    # type 7
    )
    checksum = 0
    for height, width in block_shapes:
        for block_y in range(0, 16, height):
            for block_x in range(0, 16, width):
                for pos_y in range(-SEARCH_RANGE, SEARCH_RANGE + 1):
                    for pos_x in range(-SEARCH_RANGE, SEARCH_RANGE + 1):
                        sad = 0
                        for y in range(height):
                            frame_y = block_y + y
                            ref_y = min(15, max(0, frame_y + pos_y))
                            for x in range(width):
                                frame_x = block_x + x
                                ref_x = min(15, max(0, frame_x + pos_x))
                                sad += abs(frame[frame_y * 16 + frame_x] - reference[ref_y * 16 + ref_x])
                        checksum += sad
    return checksum
