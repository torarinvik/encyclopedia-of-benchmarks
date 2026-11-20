"""Slow input-record scan and cut-enumeration reference for the certificate."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MIN_K = 1
MAX_K = 3
MAX_PARSEABLE_INPUT_LENGTH = 60
MAX_OUTPUT_BYTES = 8 * (1 + MAX_M)


def _parse(values: Sequence[int]):
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m, k = values[:3]
    if (not 3 <= n <= MAX_N or not 0 <= m <= MAX_M or not MIN_K <= k <= MAX_K
            or len(values) != 3 + 2 * m):
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(m):
        edge = (values[3 + 2 * index], values[4 + 2 * index])
        if not 0 <= edge[0] < edge[1] < n or edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return n, m, k, edges


def _scan_reference(n: int, edges: list[tuple[int, int]]) -> list[int]:
    ranks = [0 for _ in range(n)]
    remaining_vertices = set(range(n))
    remaining_edges = set(range(len(edges)))
    labels = [0 for _ in edges]
    for _ in range(n):
        x = min(remaining_vertices, key=lambda vertex: (-ranks[vertex], vertex))
        for edge_id, (u, v) in enumerate(edges):
            if edge_id not in remaining_edges or x not in (u, v):
                continue
            y = u if v == x else v
            labels[edge_id] = ranks[y] + 1
            if ranks[x] == ranks[y]:
                ranks[x] += 1
            ranks[y] += 1
            remaining_edges.remove(edge_id)
        remaining_vertices.remove(x)
    return labels


def certificate_preserves_pairwise_connectivity(
        values: Sequence[int], output_labels: Sequence[int]) -> bool:
    """Check the certificate theorem by enumerating every separating cut."""
    parsed = _parse(values)
    if parsed is None:
        return False
    n, m, k, edges = parsed
    if (len(output_labels) != m
            or any(type(label) is not int or not 0 <= label <= k for label in output_labels)):
        return False

    for source in range(n):
        for target in range(source + 1, n):
            original_min = m + 1
            certificate_min = m + 1
            for side in range(1 << n):
                if not (side >> source) & 1 or (side >> target) & 1:
                    continue
                original_cut = 0
                certificate_cut = 0
                for edge_id, (u, v) in enumerate(edges):
                    if ((side >> u) & 1) != ((side >> v) & 1):
                        original_cut += 1
                        if output_labels[edge_id] != 0:
                            certificate_cut += 1
                original_min = min(original_min, original_cut)
                certificate_min = min(certificate_min, certificate_cut)
            if min(k, original_min) != min(k, certificate_min):
                return False
    return True


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, m, k, edges = parsed
    labels = _scan_reference(n, edges)
    visible = [label if label <= k else 0 for label in labels]
    if not certificate_preserves_pairwise_connectivity(values, visible):
        raise AssertionError("FOREST output fails the pairwise cut certificate property")
    payload = struct.pack("<" + "q" * (m + 1), m, *visible)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
