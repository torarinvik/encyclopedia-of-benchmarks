"""Reference for the shared abstract bag operations contract."""

from __future__ import annotations

import struct

MAX_INSERTS = 128
MAX_QUERIES = 64
MIN_VALUE = -(1 << 31)
MAX_VALUE = (1 << 31) - 1


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    insert_count = values[0]
    if not 0 <= insert_count <= MAX_INSERTS or len(values) < insert_count + 2:
        return -1, b""
    inserted = values[1:insert_count + 1]
    query_count = values[insert_count + 1]
    queries = values[insert_count + 2:]
    if (any(not MIN_VALUE <= value <= MAX_VALUE for value in inserted)
            or not 0 <= query_count <= MAX_QUERIES or len(queries) != query_count
            or any(not MIN_VALUE <= value <= MAX_VALUE for value in queries)):
        return -1, b""
    output_values = [insert_count, int(insert_count == 0)]
    output_values.extend(int(query in inserted) for query in queries)
    encoded = struct.pack("<" + "q" * len(output_values), *output_values)
    return len(encoded), encoded
