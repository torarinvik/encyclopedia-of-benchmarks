"""Pair-enumeration oracle for the bounded Rodinia MUMmerGPU MEM query."""

from collections.abc import Sequence
import struct

MAX_REF = 32
MAX_QUERY = 32
MAX_INPUT_LENGTH = 3 + MAX_REF + MAX_QUERY
MAX_OUTPUT_BYTES = MAX_REF * MAX_QUERY * 24
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int]) -> bytes | None:
    """Enumerate all left- and right-maximal exact match pairs directly."""
    if not isinstance(values, (tuple, list)) or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    ref_length, query_length, min_length = values[:3]
    if not 1 <= ref_length <= MAX_REF or not 1 <= query_length <= MAX_QUERY:
        return None
    if not 1 <= min_length <= MAX_QUERY or len(values) != 3 + ref_length + query_length:
        return None
    reference = values[3:3 + ref_length]
    query = values[3 + ref_length:]
    if any(not 0 <= code <= 3 for code in (*reference, *query)):
        return None

    # The source traverses suffix-tree children in A,C,G,T,$ order. Use the
    # corresponding terminated-suffix lexicographic order after query position.
    suffix_order = sorted(range(ref_length), key=lambda start: tuple(reference[start:]) + (4,))
    records: list[tuple[int, int, int]] = []
    for query_start in range(query_length):
        for ref_start in suffix_order:
            match_length = 0
            while (ref_start + match_length < ref_length
                   and query_start + match_length < query_length
                   and reference[ref_start + match_length] == query[query_start + match_length]):
                match_length += 1
            if match_length < min_length:
                continue
            left_maximal = (query_start == 0 or ref_start == 0
                            or query[query_start - 1] != reference[ref_start - 1])
            right_maximal = (query_start + match_length == query_length
                             or ref_start + match_length == ref_length
                             or query[query_start + match_length] != reference[ref_start + match_length])
            if left_maximal and right_maximal:
                # Match the source text output's 1-based ref/query coordinates
                # and field order: reference, query, match length.
                records.append((ref_start + 1, query_start + 1, match_length))
    return b"".join(struct.pack("<qqq", *record) for record in records)


def expected_result(values: Sequence[int], output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False) -> int:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    encoded = expected_output(values)
    if encoded is None:
        return INVALID_RESULT
    if output_is_null or output_capacity < len(encoded):
        return OUTPUT_ERROR
    return len(encoded)
