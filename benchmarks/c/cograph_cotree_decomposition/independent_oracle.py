"""Module-enumeration reference for the canonical cograph cotree."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 12
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
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
    n, m = values[:2]
    if (not 1 <= n <= MAX_VERTICES or not 0 <= m <= n * (n - 1) // 2
            or len(values) != 2 + 2 * m):
        return None
    adjacency = [0] * n
    for i in range(m):
        u, v = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v or adjacency[u] & (1 << v):
            return None
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
    return n, adjacency


def _module(mask: int, adjacency: list[int], n: int) -> bool:
    for outside in range(n):
        if mask & (1 << outside):
            continue
        neighbors = adjacency[outside] & mask
        if neighbors and neighbors != mask:
            return False
    return True


def _has_induced_p4(adjacency: list[int], n: int) -> bool:
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                for d in range(c + 1, n):
                    vertices = (a, b, c, d)
                    degrees = [0, 0, 0, 0]
                    edge_count = 0
                    for i in range(4):
                        for j in range(i + 1, 4):
                            if adjacency[vertices[i]] & (1 << vertices[j]):
                                edge_count += 1
                                degrees[i] += 1
                                degrees[j] += 1
                    if edge_count == 3 and sorted(degrees) == [1, 1, 2, 2]:
                        return True
    return False


def _emit(mask: int, strong: list[int], adjacency: list[int], n: int) -> list[int] | None:
    if mask & (mask - 1) == 0:
        return [0, mask.bit_length() - 1]
    children = [part for part in strong if part != mask and part & mask == part]
    immediate = []
    for part in children:
        if not any(part != middle and middle != mask and part & middle == part
                   and middle & mask == middle for middle in children):
            immediate.append(part)
    immediate.sort(key=lambda part: (part & -part).bit_length())
    if len(immediate) < 2:
        return None
    node_kind: int | None = None
    for i, left in enumerate(immediate):
        for right in immediate[i + 1:]:
            for u in range(n):
                if not (left & (1 << u)):
                    continue
                for v in range(n):
                    if not (right & (1 << v)):
                        continue
                    relation = 2 if adjacency[u] & (1 << v) else 1
                    if node_kind is None:
                        node_kind = relation
                    elif node_kind != relation:
                        return None  # a prime quotient, not a cograph node
    if node_kind is None:
        return None
    tokens = [node_kind, len(immediate)]
    for child_mask in immediate:
        child_tokens = _emit(child_mask, strong, adjacency, n)
        if child_tokens is None:
            return None
        tokens.extend(child_tokens)
    return tokens


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> bytes | None:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return None
    n, adjacency = parsed
    if _has_induced_p4(adjacency, n):
        return b"\x00"
    modules = [mask for mask in range(1, 1 << n) if _module(mask, adjacency, n)]
    strong: list[int] = []
    for candidate in modules:
        is_strong = True
        for other in modules:
            overlap = candidate & other
            if overlap and overlap != candidate and overlap != other:
                is_strong = False
                break
        if is_strong:
            strong.append(candidate)
    tokens = _emit((1 << n) - 1, strong, adjacency, n)
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
