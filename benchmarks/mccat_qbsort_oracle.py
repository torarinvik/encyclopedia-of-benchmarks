"""Independent oracle for the bounded McCat 01-qbsort adapter."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_COUNT = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_COUNT
MAX_OUTPUT_BYTES = 4 * MAX_COUNT
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
INVALID_RESULT, OUTPUT_ERROR = -1, -2
PINNED_SOURCE = {
    "repository": "lac-dcc/Benchmarks",
    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
    "path": "McCat/01-qbsort/sort.c",
    "method": "BubbleSort and QuickSort",
    "signature": "BubbleSort(List *, compare); QuickSort(LinkList *, compare)",
    "url": "https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/01-qbsort/sort.c",
    "role": "algorithm",
}


def _bubble(values: list[int]) -> list[int]:
    result = values.copy()
    for end in range(len(result) - 1, 0, -1):
        for i in range(end):
            if result[i + 1] < result[i]:
                result[i], result[i + 1] = result[i + 1], result[i]
    return result


def _quick(values: list[int]) -> list[int]:
    if not values:
        return []
    pivot = values[0]
    lower = [value for value in values[1:] if value < pivot]
    upper = [value for value in values[1:] if value >= pivot]
    return _quick(lower) + [pivot] + _quick(upper)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if not isinstance(values, (list, tuple)) or input_is_null:
        return INVALID_RESULT, b""
    if any(type(v) is not int or not I64_MIN <= v <= I64_MAX for v in values):
        return INVALID_RESULT, b""
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values) or not 2 <= declared <= MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    mode, count = values[:2]
    if mode not in (0, 1) or not 1 <= count <= MAX_COUNT or declared != count + 2:
        return INVALID_RESULT, b""
    items = values[2:]
    if any(not I32_MIN <= value <= I32_MAX for value in items):
        return INVALID_RESULT, b""
    sorted_items = _bubble(items) if mode == 0 else _quick(items)
    output = b"".join(struct.pack("<i", value) for value in sorted_items)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
