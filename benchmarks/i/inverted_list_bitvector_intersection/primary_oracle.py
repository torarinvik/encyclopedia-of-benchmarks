"""Set-conversion oracle for packed inverted-list bitvectors."""
from __future__ import annotations

from collections.abc import Sequence

MAX_DOMAIN = 1024
MAX_LISTS = 16
MAX_WORDS = MAX_DOMAIN // 64
MAX_INPUT_LENGTH = 2 + MAX_LISTS * MAX_WORDS
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * (MAX_DOMAIN + 1)
MAX_WORKSPACE_BYTES = 8320
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) < 2
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    domain, list_count = values[0], values[1]
    if not 1 <= domain <= MAX_DOMAIN or not 1 <= list_count <= MAX_LISTS:
        return None
    words_per_list = (domain + 63) // 64
    if len(values) != 2 + list_count * words_per_list:
        return None
    remainder = domain % 64
    if remainder:
        valid_mask = (1 << remainder) - 1
        for list_index in range(list_count):
            final_word = values[2 + list_index * words_per_list + words_per_list - 1]
            if (final_word & ((1 << 64) - 1)) & ~valid_mask:
                return None
    return domain, list_count, words_per_list


def _intersection(values: Sequence[int], domain: int,
                  list_count: int, words_per_list: int) -> list[int]:
    lists: list[set[int]] = []
    for list_index in range(list_count):
        members: set[int] = set()
        base = 2 + list_index * words_per_list
        for document_id in range(domain):
            word = values[base + document_id // 64] & ((1 << 64) - 1)
            if (word >> (document_id % 64)) & 1:
                members.add(document_id)
        lists.append(members)
    common = lists[0]
    for members in lists[1:]:
        common = common.intersection(members)
    return sorted(common)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    document_ids = _intersection(values, *parsed)
    result_vector = (len(document_ids), *document_ids)
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in result_vector)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload
