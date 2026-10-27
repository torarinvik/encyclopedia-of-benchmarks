"""Independent verifier using sorted facet tuples and ordered-set encoding."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 51


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and len(values) != input_length:
        return -1, b""
    if not 3 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    sample_count, pole_count, facet_count = values[:3]
    if not 3 <= sample_count <= 8 or not 1 <= pole_count <= 4 or sample_count + pole_count > 12 or not 0 <= facet_count <= 16:
        return -1, b""
    if len(values) != 3 + 3 * facet_count:
        return -1, b""
    total = sample_count + pole_count
    facets = []
    for i in range(facet_count):
        a, b, c = values[3 + 3*i:6 + 3*i]
        if not 0 <= a < total or not 0 <= b < total or not 0 <= c < total or a == b or a == c or b == c:
            return -1, b""
        if a < sample_count and b < sample_count and c < sample_count:
            facets.append(tuple(sorted((a, b, c))))
    output_triangles = sorted(set(facets))
    words = [len(output_triangles)]
    for triangle in output_triangles:
        words.extend(triangle)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
