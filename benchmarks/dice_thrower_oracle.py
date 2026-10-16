"""Bounded newline-delimited oracle for the pinned recursive dice thrower."""

from __future__ import annotations

MAX_INPUT_LENGTH = 1
MAX_TARGET = 8
MAX_OUTPUT_BYTES = 696


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) != 1
            or type(values[0]) is not int or not -(2**63) <= values[0] < 2**63):
        return -1, b""
    target = values[0]
    if not 0 <= target <= MAX_TARGET:
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    combinations: list[bytes] = []

    def visit(remaining: int, prefix: bytes) -> None:
        if remaining == 0:
            combinations.append(prefix + b"\n")
            return
        for face in range(1, min(6, remaining) + 1):
            visit(remaining - face, prefix + bytes((48 + face,)))

    visit(target, b"")
    output = b"".join(combinations)
    if output_capacity is not None and output_capacity < len(output):
        return -2, b""
    return len(output), output
