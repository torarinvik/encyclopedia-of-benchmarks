"""Oracle for flattening bounded sorted child-linked columns."""
from __future__ import annotations
import struct

MAX_LISTS = 8
MAX_CHAIN_LENGTH = 8
MAX_TOTAL_VALUES = MAX_LISTS * MAX_CHAIN_LENGTH
MAX_INPUT_LENGTH = 1 + MAX_LISTS * (1 + MAX_CHAIN_LENGTH)
# Allow one additional integer so the recorder can pass an overlong invalid
# record to the oracle/implementation while keeping valid inputs capped above.
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_TOTAL_VALUES * 8
MIN_VALUE = -1000
MAX_VALUE = 1000


def expected_output(values: list[int] | tuple[int, ...], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_LISTS:
        return -1, b""
    cursor = 1
    columns = []
    for _ in range(count):
        if cursor >= len(values): return -1, b""
        size = values[cursor]; cursor += 1
        if not 1 <= size <= MAX_CHAIN_LENGTH or cursor + size > len(values): return -1, b""
        col = list(values[cursor:cursor + size]); cursor += size
        if any(not MIN_VALUE <= x <= MAX_VALUE for x in col) or any(col[i - 1] > col[i] for i in range(1, size)):
            return -1, b""
        columns.append(col)
    if cursor != len(values): return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0): return -1, b""
    flattened = []
    for col in reversed(columns):
        flattened = _merge(col, flattened)
    output = b"".join(struct.pack("<q", x) for x in flattened)
    if output_capacity is not None and output_capacity < len(output): return -2, b""
    return len(flattened), output


def _merge(left, right):
    out=[]; i=j=0
    while i < len(left) and j < len(right):
        if left[i] < right[j]: out.append(left[i]); i += 1
        else: out.append(right[j]); j += 1
    out.extend(left[i:]); out.extend(right[j:])
    return out
