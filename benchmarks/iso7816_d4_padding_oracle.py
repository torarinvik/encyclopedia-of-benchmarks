from collections.abc import Sequence

MAX_INPUT_LENGTH = 27
MAX_BYTE_COUNT = 24

def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1

    mode, block_size, byte_count = values[:3]
    if mode not in (0, 1, 2) or not 0 <= byte_count <= MAX_BYTE_COUNT or len(values) != byte_count + 3:
        return -1
    if (mode == 0 and not 1 <= block_size <= 8) or (mode != 0 and block_size != 0):
        return -1

    data = values[3:]
    if any(byte < 0 or byte > 255 for byte in data):
        return -1

    if mode == 0:
        padded_length = (byte_count // block_size + 1) * block_size
        return padded_length - byte_count if padded_length <= 32 else -1

    if mode == 1:
        marker = byte_count - 1
        while marker >= 0 and data[marker] == 0:
            marker -= 1
        return marker if marker >= 0 and data[marker] == 0x80 else -1

    marker = -1
    zero_suffix = True
    for index in range(byte_count - 1, -1, -1):
        if zero_suffix and data[index] == 0x80:
            marker = index
        if data[index] != 0:
            zero_suffix = False
    return byte_count - marker if marker >= 0 else -1
