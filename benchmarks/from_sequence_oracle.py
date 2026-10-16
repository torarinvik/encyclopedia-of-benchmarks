"""Oracle for the bounded Python linked-list from_sequence constructor."""
from __future__ import annotations

MAX_NODE_COUNT = 128
MAX_INPUT_LENGTH = MAX_NODE_COUNT + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 3_589
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def expected_output(values: list[int], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT, b""
    count = values[0]
    payload = values[1:]
    if not 1 <= count <= MAX_NODE_COUNT or len(payload) != count:
        return INVALID_RESULT, b""
    output = ("".join(f"<{value}> ---> " for value in payload) + "<END>").encode("ascii")
    if output_capacity is not None and output_capacity < len(output):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
