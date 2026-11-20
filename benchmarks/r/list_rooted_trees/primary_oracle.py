"""Multiset-recursion reference for unordered rooted-tree enumeration."""

from __future__ import annotations

MAX_VERTICES = 7
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_TREE_COUNT = 48
MAX_OUTPUT_BYTES = 2 + MAX_TREE_COUNT * (2 * MAX_VERTICES)
TREE_COUNTS = (0, 1, 1, 2, 4, 9, 20, 48)


def _shapes_by_size(maximum: int) -> list[list[bytes]]:
    levels: list[list[bytes]] = [[] for _ in range(maximum + 1)]
    if maximum < 1:
        return levels
    levels[1] = [b"()"]
    for size in range(2, maximum + 1):
        candidates = sorted(
            (shape for child_size in range(1, size) for shape in levels[child_size]),
        )
        candidate_sizes = {shape: shape.count(b"(") for shape in candidates}
        generated: list[bytes] = []

        def choose(start: int, remaining: int, children: list[bytes]) -> None:
            if remaining == 0:
                generated.append(b"(" + b"".join(children) + b")")
                return
            for index in range(start, len(candidates)):
                shape = candidates[index]
                child_size = candidate_sizes[shape]
                if child_size <= remaining:
                    choose(index, remaining - child_size, children + [shape])

        choose(0, size - 1, [])
        levels[size] = sorted(set(generated))
    return levels


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if len(values) != 1 or not 1 <= values[0] <= MAX_VERTICES:
        return -1, b""
    size = values[0]
    shapes = _shapes_by_size(size)[size]
    output = bytearray((len(shapes) & 255, len(shapes) >> 8))
    for shape in shapes:
        output.extend(shape)
    return len(output), bytes(output)
