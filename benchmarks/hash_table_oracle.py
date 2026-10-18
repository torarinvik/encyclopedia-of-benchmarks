"""Independent oracle for the collision-free integer-membership hash-table contract."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_KEY = 1
MAX_KEY = 1000
MAX_INSERT_COUNT = 8
MAX_QUERY_COUNT = 8
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_BYTES = 8 * MAX_QUERY_COUNT


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (tuple, list))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1, b""

    insert_count = values[0]
    if not 0 <= insert_count <= MAX_INSERT_COUNT:
        return -1, b""
    query_count_index = 1 + insert_count
    if query_count_index >= len(values):
        return -1, b""
    query_count = values[query_count_index]
    if not 1 <= query_count <= MAX_QUERY_COUNT:
        return -1, b""
    if len(values) != query_count_index + 1 + query_count:
        return -1, b""

    inserted = list(values[1:query_count_index])
    queries = list(values[query_count_index + 1:])
    if any(not MIN_KEY <= key <= MAX_KEY for key in inserted + queries):
        return -1, b""
    if len(set(inserted)) != len(inserted) or len(set(queries)) != len(queries):
        return -1, b""

    distinct_keys = set(inserted + queries)
    distinct_list = sorted(distinct_keys)
    for index, key in enumerate(distinct_list):
        for other in distinct_list[index + 1:]:
            if key % 17 == other % 17 or key % 3000 == other % 3000:
                return -1, b""

    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null:
        return -2, b""

    inserted_set = set(inserted)
    output = b"".join(struct.pack("<q", int(query in inserted_set)) for query in queries)
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
