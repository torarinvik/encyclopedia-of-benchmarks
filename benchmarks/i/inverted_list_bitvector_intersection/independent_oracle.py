"""Independent per-document verifier for bitvector intersections."""
from __future__ import annotations

from collections.abc import Sequence

MAX_DOMAIN = 1024
MAX_LISTS = 16
MAX_WORDS = MAX_DOMAIN // 64
MAX_VALID_INPUT_LENGTH = 2 + MAX_LISTS * MAX_WORDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * (MAX_DOMAIN + 1)
MAX_WORKSPACE_BYTES = 8320


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
    words = (domain + 63) // 64
    if len(values) != 2 + list_count * words:
        return None
    remaining = domain % 64
    if remaining:
        allowed = (1 << remaining) - 1
        for row in range(list_count):
            raw = values[2 + row * words + words - 1] & ((1 << 64) - 1)
            if raw & ~allowed:
                return None
    return domain, list_count, words


def _expected_vector(values: Sequence[int], domain: int,
                     list_count: int, words: int) -> list[int]:
    result: list[int] = []
    for document_id in range(domain):
        belongs_to_all = True
        for row in range(list_count):
            word = values[2 + row * words + document_id // 64] & ((1 << 64) - 1)
            if ((word >> (document_id % 64)) & 1) == 0:
                belongs_to_all = False
                break
        if belongs_to_all:
            result.append(document_id)
    return [len(result), *result]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    vector = _expected_vector(values, *parsed)
    expected = b"".join(value.to_bytes(8, "little", signed=True) for value in vector)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int or capacity < 0
            or output_is_null or capacity < len(expected)):
        return -2, b""
    return len(expected), expected


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    expected_result, expected = expected_output(
        values, output_capacity=output_capacity, output_is_null=output_is_null,
        input_is_null=input_is_null, input_length=input_length)
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and output == b""
    if expected_result == -2:
        return result == -2 and output == b""
    if not isinstance(output, (bytes, bytearray)):
        return False
    if result != expected_result or len(output) != len(expected):
        return False
    decoded = [int.from_bytes(output[offset:offset + 8], "little", signed=True)
               for offset in range(0, len(output), 8)]
    return decoded == _expected_vector(values, *parsed)
