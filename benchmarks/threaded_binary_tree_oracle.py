"""Oracle for the bounded insert-only threaded binary tree benchmark."""

from __future__ import annotations

MAX_NODES = 128
MAX_INPUT_LENGTH = MAX_NODES + 1
MAX_OUTPUT_LENGTH = MAX_NODES * 4
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return (byte_count, inorder_i32_bytes), or (-1, b"") for invalid input."""
    if not isinstance(values, (list, tuple)) or not values:
        return -1, b""
    if any(type(value) is not int or not MIN_I64 <= value <= MAX_I64 for value in values):
        return -1, b""

    count = values[0]
    if count < 0 or count > MAX_NODES or len(values) != 1 + count:
        return -1, b""
    keys = values[1:]
    if any(key < MIN_I32 or key > MAX_I32 for key in keys):
        return -1, b""

    output = b"".join((key & 0xFFFFFFFF).to_bytes(4, "little") for key in sorted(keys))
    return len(output), output
