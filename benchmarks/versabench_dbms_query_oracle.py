"""Independent oracle for the bounded key-only VersaBench R-tree query."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 7
MAX_ENTRIES = 4
MAX_LEAF_RECORDS = 16
MAX_INPUT_LENGTH = 10 + 38 * MAX_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_LEAF_RECORDS


def _valid_box(lo: Sequence[int], hi: Sequence[int]) -> bool:
    return all(-8 <= lo[d] < hi[d] <= 8 for d in range(4))


def _intersects(a: tuple[tuple[int, ...], tuple[int, ...]],
                qlo: Sequence[int], qhi: Sequence[int]) -> bool:
    lo, hi = a
    return all(not (qlo[d] > hi[d] or lo[d] > qhi[d]) for d in range(4))


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    if len(values) < 10:
        return -1, b""
    node_count, root = values[0], values[1]
    if not 1 <= node_count <= MAX_NODES or not 0 <= root < node_count:
        return -1, b""
    qlo, qhi = tuple(values[2:6]), tuple(values[6:10])
    if not _valid_box(qlo, qhi):
        return -1, b""

    nodes: list[dict] = []
    parents = [0] * node_count
    data_ids: set[int] = set()
    leaf_total = 0
    cursor = 10
    for _ in range(node_count):
        if cursor + 2 > len(values):
            return -1, b""
        level, entry_count = values[cursor:cursor+2]
        cursor += 2
        if not 0 <= level <= 2 or not 1 <= entry_count <= MAX_ENTRIES:
            return -1, b""
        entries = []
        for _entry in range(entry_count):
            if cursor + 9 > len(values):
                return -1, b""
            lo = tuple(values[cursor:cursor+4])
            hi = tuple(values[cursor+4:cursor+8])
            ref = values[cursor+8]
            cursor += 9
            if not _valid_box(lo, hi):
                return -1, b""
            if level == 0:
                if not 0 <= ref < 32 or ref in data_ids:
                    return -1, b""
                data_ids.add(ref)
                leaf_total += 1
                if leaf_total > MAX_LEAF_RECORDS:
                    return -1, b""
            else:
                if not 0 <= ref < node_count:
                    return -1, b""
                parents[ref] += 1
                if parents[ref] > 1:
                    return -1, b""
            entries.append((lo, hi, ref))
        nodes.append({"level": level, "entries": entries})
    if cursor != len(values) or parents[root] != 0:
        return -1, b""

    for node_id, node in enumerate(nodes):
        if node_id != root and parents[node_id] != 1:
            return -1, b""
        if node["level"] == 0:
            continue
        for lo, hi, child_id in node["entries"]:
            child = nodes[child_id]
            if child["level"] != node["level"] - 1:
                return -1, b""
            if any(lo[d] > child_lo[d] or hi[d] < child_hi[d]
                   for child_lo, child_hi, _ in child["entries"] for d in range(4)):
                return -1, b""

    hits: list[int] = []

    def visit(node_id: int) -> None:
        node = nodes[node_id]
        if node["level"] == 0:
            for lo, hi, record_id in node["entries"]:
                if _intersects((lo, hi), qlo, qhi):
                    hits.append(record_id)
        else:
            for lo, hi, child_id in node["entries"]:
                if _intersects((lo, hi), qlo, qhi):
                    visit(child_id)

    visit(root)
    output = b"".join(struct.pack("<q", record_id) for record_id in hits)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output


oracle = expected_output
