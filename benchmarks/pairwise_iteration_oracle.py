"""Oracle for the pinned adjacent-pair iterator on bounded integer sequences."""
import struct

MAX_INPUT_LENGTH = 129
MAX_ITEMS = 128
MAX_VALUE = 1_000_000
MAX_OUTPUT_BYTES = (MAX_ITEMS - 1) * 16


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return -1, b""
    count = values[0]
    items = values[1:]
    if type(count) is not int or not 0 <= count <= MAX_ITEMS or len(items) != count:
        return -1, b""
    if any(x < -MAX_VALUE or x > MAX_VALUE for x in items):
        return -1, b""
    output = b"".join(struct.pack("<q", x) for pair in zip(items, items[1:]) for x in pair)
    return len(output), output
