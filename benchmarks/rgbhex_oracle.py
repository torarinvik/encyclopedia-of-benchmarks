"""Independent oracle for the pinned Go RGB/hex conversion pair."""

MAX_INPUT_LENGTH = 5
MAX_RGB = 0xFFFFFFFF

def expected_result(values: list[int]) -> int:
    if len(values) != 4:
        return -1
    op, x, y, z = values
    if op == 0:
        if 0 <= x <= MAX_RGB and y == 0 and z == 0:
            return x & 0x00FFFFFF
        return -1
    if op == 1:
        if all(0 <= channel <= 255 for channel in (x, y, z)):
            return (x << 16) | (y << 8) | z
    return -1
