"""Oracle for the include-first recursive power-set traversal."""

from __future__ import annotations

MAX_ITEMS = 12
MAX_INPUT_LENGTH = MAX_ITEMS + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 + 4 * (1 << MAX_ITEMS) + MAX_ITEMS * (1 << (MAX_ITEMS - 1))


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    n = values[0]
    if not 0 <= n <= MAX_ITEMS or len(values) != n + 1:
        return -1, b""
    if any(not 0 <= value <= 0x7F for value in values[1:]):
        return -1, b""

    subsets: list[bytes] = []
    selected: list[int] = []

    def visit(index: int) -> None:
        if index == n:
            subsets.append(bytes(selected))
            return
        selected.append(values[index + 1])
        visit(index + 1)
        selected.pop()
        visit(index + 1)

    visit(0)
    output = bytearray(len(subsets).to_bytes(4, "little"))
    for subset in subsets:
        output.extend(len(subset).to_bytes(4, "little"))
        output.extend(subset)
    result = len(output)
    if result > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_capacity < result:
        return -2, b""
    return result, bytes(output)
