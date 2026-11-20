"""Independent transition-map reference for bounded Pearson hashing."""

BYTE_DOMAIN = range(256)
MAX_TEXT_LENGTH = 64
MAX_RAW_WORDS = 322


def expected_result(values: list[int]) -> int:
    if not 257 <= len(values) <= MAX_RAW_WORDS:
        return -1
    count = values[0]
    if not isinstance(count, int) or isinstance(count, bool):
        return -1
    if not 0 <= count <= MAX_TEXT_LENGTH + 1:
        return -1
    if len(values) != 257 + count or count > MAX_TEXT_LENGTH:
        return -1

    permutation = values[1:257]
    used = [False] * 256
    for value in permutation:
        if not isinstance(value, int) or isinstance(value, bool) or value not in BYTE_DOMAIN:
            return -1
        if used[value]:
            return -1
        used[value] = True

    message = values[257:]
    for byte in message:
        if not isinstance(byte, int) or isinstance(byte, bool) or byte not in BYTE_DOMAIN:
            return -1

    # Track the image of every possible starting state. Each input byte
    # composes another transition into this map; the result is its image at 0.
    image = list(BYTE_DOMAIN)
    for byte in message:
        image = [permutation[prior ^ byte] for prior in image]
    return image[0]
