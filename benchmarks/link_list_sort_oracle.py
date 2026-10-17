"""Oracle for the bounded Java linked-list sort adapter."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_ITEMS = 128
MAX_VALID_INPUT_LENGTH = 2 + MAX_ITEMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_OUTPUT_BYTES = 4 * MAX_ITEMS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
CASE_IDS = frozenset({
    "merge_empty_input", "insertion_empty_input", "heap_empty_input",
    "merge_singleton", "insertion_singleton_int32_min", "heap_singleton_int32_max",
    "merge_mixed_and_duplicates", "insertion_negative_duplicates",
    "heap_boundary_and_duplicates", "merge_already_sorted", "insertion_reverse",
    "heap_duplicate_only", "merge_int32_extremes", "maximum_items_and_output",
    "empty_output_capacity_zero", "null_output_empty", "null_output_nonempty",
    "short_output_capacity", "exact_nonempty_output_capacity", "invalid_selector_precedes_null_output",
    "trailing_input_word", "item_out_of_i32_range", "selector_above_domain",
    "negative_item_count", "count_above_bound", "truncated_items",
    "null_input_positive_length",
})
PINNED_SOURCE = {
    "repository": "TheAlgorithms/Java",
    "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
    "path": "src/main/java/com/thealgorithms/sorts/LinkListSort.java",
    "method": "isSorted",
    "signature": "isSorted(int[] p, int option)",
    "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/LinkListSort.java",
    "role": "algorithm",
}


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return sorted signed-i32 output bytes and byte-count status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or (input_is_null and values)
        or (not input_is_null and declared_length != len(values))
        or declared_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT, b""
    if input_is_null or declared_length < 2:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""

    selector, item_count = values[:2]
    if selector not in (1, 2, 3) or not 0 <= item_count <= MAX_ITEMS:
        return INVALID_RESULT, b""
    if declared_length != 2 + item_count:
        return INVALID_RESULT, b""
    items = values[2:]
    if any(not I32_MIN <= value <= I32_MAX for value in items):
        return INVALID_RESULT, b""

    output = b"".join(struct.pack("<i", value) for value in sorted(items))
    if len(output) > MAX_OUTPUT_BYTES:
        raise AssertionError("link_list_sort output exceeds its published bound")
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
