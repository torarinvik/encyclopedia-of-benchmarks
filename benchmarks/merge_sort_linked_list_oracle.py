"""Oracle for the bounded pinned Python linked-list merge sort."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_ITEMS = 128
MAX_VALID_INPUT_LENGTH = 1 + MAX_ITEMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_OUTPUT_BYTES = 4 * MAX_ITEMS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
CASE_IDS = frozenset({
    "empty_list", "singleton", "two_nodes_reverse", "even_reverse",
    "odd_mixed", "already_sorted", "interleaved_halves", "int32_extremes",
    "maximum_items_and_output", "empty_output_capacity_zero", "null_output_empty",
    "null_output_nonempty", "short_output_capacity", "exact_output_capacity",
    "max_output_capacity", "max_output_one_byte_short", "duplicate_data_invalid", "item_out_of_i32_range",
    "negative_count", "count_above_bound", "truncated_items", "trailing_input_word",
    "null_input_positive_length",
})
PINNED_SOURCE = {
    "repository": "TheAlgorithms/Python",
    "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
    "path": "data_structures/linked_list/merge_sort_linked_list.py",
    "method": "merge_sort_linked_list",
    "signature": "merge_sort_linked_list(head: Node | None) -> Node | None",
    "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/merge_sort_linked_list.py",
    "role": "algorithm",
}


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return sorted signed-i32 bytes or the source adapter's ABI status."""
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
        or input_is_null
        or declared_length < 1
    ):
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""

    count = values[0]
    if not 0 <= count <= MAX_ITEMS or declared_length != 1 + count:
        return INVALID_RESULT, b""
    items = values[1:]
    if any(not I32_MIN <= value <= I32_MAX for value in items) or len(set(items)) != count:
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<i", value) for value in sorted(items))
    if len(output) > MAX_OUTPUT_BYTES:
        raise AssertionError("merge_sort_linked_list output exceeds its published bound")
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
