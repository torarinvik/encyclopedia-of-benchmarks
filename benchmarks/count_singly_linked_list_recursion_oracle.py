"""Oracle for the bounded recursive singly linked-list count benchmark."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
I32_MIN = -(2**31)
I32_MAX = 2**31 - 1
MAX_NODES = 64
MAX_INPUT_LENGTH = MAX_NODES + 2  # include one oversized invalid payload


def expected_result(values: list[int]) -> int:
    """Return the represented chain length, or -1 for malformed input."""
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    node_count = values[0]
    if not 0 <= node_count <= MAX_NODES or len(values) != node_count + 1:
        return -1
    if any(not I32_MIN <= payload <= I32_MAX for payload in values[1:]):
        return -1
    return sum(1 for _payload in values[1:])
