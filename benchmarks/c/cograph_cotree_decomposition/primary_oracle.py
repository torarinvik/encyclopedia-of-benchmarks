"""Bounded connected/co-connected recursive cograph cotree reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 12
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 1 + 2 * (2 * MAX_VERTICES - 1)
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count, edge_count = values[:2]
    if (not 1 <= count <= MAX_VERTICES or not 0 <= edge_count <= count * (count - 1) // 2
            or len(values) != 2 + 2 * edge_count):
        return None
    adjacency = [0] * count
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left < count or not 0 <= right < count or left == right:
            return None
        bit_left, bit_right = 1 << left, 1 << right
        if adjacency[left] & bit_right:
            return None
        adjacency[left] |= bit_right
        adjacency[right] |= bit_left
    return count, adjacency


def _components(mask: int, adjacency: list[int], complement: bool) -> list[int]:
    remaining = mask
    result: list[int] = []
    while remaining:
        root_bit = remaining & -remaining
        remaining ^= root_bit
        component = root_bit
        queue = [root_bit.bit_length() - 1]
        cursor = 0
        while cursor < len(queue):
            vertex = queue[cursor]
            cursor += 1
            possible = adjacency[vertex] & mask
            if complement:
                possible = mask & ~adjacency[vertex] & ~(1 << vertex)
            fresh = possible & ~component
            while fresh:
                bit = fresh & -fresh
                fresh ^= bit
                component |= bit
                queue.append(bit.bit_length() - 1)
        result.append(component)
        remaining &= ~component
    return result


def _tree_tokens(mask: int, adjacency: list[int]) -> list[int] | None:
    if mask & (mask - 1) == 0:
        return [0, mask.bit_length() - 1]

    parts = _components(mask, adjacency, complement=False)
    if len(parts) > 1:
        node_kind = 1  # disjoint union
    else:
        parts = _components(mask, adjacency, complement=True)
        if len(parts) <= 1:
            return None
        node_kind = 2  # complete join

    # Components are discovered by ascending least vertex, which fixes child order.
    tokens = [node_kind, len(parts)]
    for part in parts:
        child = _tree_tokens(part, adjacency)
        if child is None:
            return None
        tokens.extend(child)
    return tokens


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> bytes | None:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return None
    count, adjacency = parsed
    tokens = _tree_tokens((1 << count) - 1, adjacency)
    if tokens is None:
        return b"\x00"
    return bytes([1, *tokens])


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    result = expected_output(values, input_is_null, input_length)
    return INVALID_RESULT if result is None else len(result)


def expected_abi_output(values: Sequence[int] | None,
                        output_capacity: int = MAX_OUTPUT_BYTES,
                        output_is_null: bool = False,
                        input_is_null: bool = False,
                        input_length: int | None = None) -> tuple[int, bytes]:
    output = expected_output(values, input_is_null, input_length)
    if output is None:
        return INVALID_RESULT, b""
    if (type(output_capacity) is not int or output_capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output
