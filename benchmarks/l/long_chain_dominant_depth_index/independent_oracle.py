"""Subtree traversal reference, independent of long-chain DP."""

from __future__ import annotations

from .primary_oracle import MAX_N, MAX_OUTPUT_BYTES, _decode


def _direct_indices(n: int, children: list[list[int]]) -> list[int]:
    answers = [0] * n
    for root in range(n):
        counts: list[int] = []
        stack = [(root, 0)]
        while stack:
            vertex, depth = stack.pop()
            if depth == len(counts):
                counts.append(0)
            counts[depth] += 1
            for child in children[vertex]:
                stack.append((child, depth + 1))
        maximum = max(counts)
        answers[root] = next(depth for depth, count in enumerate(counts) if count == maximum)
    return answers


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None,
                    output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    n, _parent, children = decoded
    required = 8 * n
    if type(output_is_null) is not bool or type(output_capacity) is not int:
        return -2, b""
    if output_is_null or output_capacity < required:
        return -2, b""
    answers = _direct_indices(n, children)
    return required, b"".join(value.to_bytes(8, "little", signed=True) for value in answers)
