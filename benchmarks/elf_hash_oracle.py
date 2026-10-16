"""Independent bounded oracle for the pinned Python ELF hash."""

MAX_VALID_INPUT_LENGTH = 8
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1  # admit the over-bound fixture


def expected_result(values: list[int]) -> int:
    if len(values) > MAX_VALID_INPUT_LENGTH:
        return -1
    if any(value < 0 or value > 127 for value in values):
        return -1

    hash_value = 0
    for codepoint in values:
        hash_value = (hash_value << 4) + codepoint
        high = hash_value & 0xF0000000
        if high:
            hash_value ^= high >> 24
        hash_value &= ~high
    return hash_value
