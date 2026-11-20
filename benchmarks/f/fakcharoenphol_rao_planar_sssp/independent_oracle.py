"""Independent original-graph Bellman-Ford verifier for the bounded profile."""
from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import (
        INF,
        INVALID_RESULT,
        MAX_OUTPUT_BYTES,
        OUTPUT_ERROR_RESULT,
        Parsed,
        parse_input,
    )
except ImportError:
    from primary_oracle import (
        INF,
        INVALID_RESULT,
        MAX_OUTPUT_BYTES,
        OUTPUT_ERROR_RESULT,
        Parsed,
        parse_input,
    )


def _bellman_ford(parsed: Parsed) -> list[int] | None:
    edges = list(parsed.edges)
    super_source = [0] * parsed.n
    for _ in range(parsed.n - 1):
        changed = False
        for u, v, weight in edges:
            if super_source[u] + weight < super_source[v]:
                super_source[v] = super_source[u] + weight
                changed = True
        if not changed:
            break
    if any(super_source[u] + weight < super_source[v]
           for u, v, weight in edges):
        return None
    labels = [INF] * parsed.n
    labels[parsed.source] = 0
    for _ in range(parsed.n - 1):
        changed = False
        for u, v, weight in edges:
            if labels[u] != INF and labels[u] + weight < labels[v]:
                labels[v] = labels[u] + weight
                changed = True
        if not changed:
            break
    for u, v, weight in edges:
        if labels[u] != INF and labels[u] + weight < labels[v]:
            return None
    return labels


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    distances = _bellman_ford(parsed)
    if distances is None:
        return INVALID_RESULT, b""
    distances = [((1 << 63) - 1 if value == INF else value) for value in distances]
    payload = b"".join(value.to_bytes(8, "little", signed=True)
                        for value in distances)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False,
                  input_length: int | None = None) -> bool:
    expected_result, expected_bytes = expected_output(
        values, capacity, output_is_null, input_is_null, input_length)
    return result == expected_result and output == expected_bytes
