"""Dense-accumulator reference, structurally independent of COO coalescing."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_N = 16
MAX_NONZER = 4
MAX_INPUT_LENGTH = 3 + 2 * MAX_N * MAX_NONZER
MAX_OUTPUT_BYTES = 8 * (MAX_N + 3 + 2 * MAX_N * MAX_N)
MAX_SHIFT_MICRO = 10_000_000
MAX_VALUE_MICRO = 1_000_000
SCALE = 1_000_000.0
RCOND = 0.1
ABSOLUTE_TOLERANCE = 1.0e-12
RELATIVE_TOLERANCE = 1.0e-12


def _decode(values: Sequence[int] | None, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 3 <= input_length <= MAX_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, nonzer, shift = values[:3]
    if (not 2 <= n <= MAX_N or not 1 <= nonzer <= MAX_NONZER
            or not 0 <= shift <= MAX_SHIFT_MICRO
            or input_length != 3 + 2 * n * nonzer):
        return None
    vectors = []
    offset = 3
    for vector_id in range(n):
        support = []
        used = set()
        for _ in range(nonzer):
            index, raw = values[offset:offset + 2]
            offset += 2
            if (not 0 <= index < n or index in used or raw == 0
                    or not -MAX_VALUE_MICRO <= raw <= MAX_VALUE_MICRO):
                return None
            used.add(index)
            support.append([index, raw / SCALE])
        for item in support:
            if item[0] == vector_id:
                item[1] = 0.5
                break
        else:
            support.append([vector_id, 0.5])
        vectors.append(support)
    return n, shift / SCALE, vectors


def _assemble_dense(decoded):
    n, shift, vectors = decoded
    dense = [[0.0] * n for _ in range(n)]
    present = [[False] * n for _ in range(n)]
    for vector_id, support in enumerate(vectors):
        if vector_id == 0:
            weight = 1.0
        elif vector_id == n - 1:
            weight = RCOND
        else:
            weight = math.pow(RCOND, vector_id / (n - 1))
        for column, column_value in support:
            for row, row_value in support:
                dense[row][column] += (weight * column_value) * row_value
                present[row][column] = True
    offset = RCOND - shift
    for diagonal in range(n):
        dense[diagonal][diagonal] += offset
        present[diagonal][diagonal] = True
    pointers = [0]
    rows = []
    entries = []
    for column in range(n):
        for row in range(n):
            if present[row][column]:
                rows.append(row)
                entries.append(dense[row][column])
        pointers.append(len(rows))
    return pointers, rows, entries


def _pack(n, pointers, rows, entries):
    fields = [float(n), float(len(rows)), *(float(value) for value in pointers),
              *(float(value) for value in rows), *entries]
    return struct.pack("<" + "d" * len(fields), *fields)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    n, _shift, _vectors = decoded
    pointers, rows, entries = _assemble_dense(decoded)
    required = 8 * (2 + (n + 1) + 2 * len(rows))
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0 or output_is_null or capacity < required):
        return -2, b""
    return required, _pack(n, pointers, rows, entries)


def validate_output(values, payload, **abi_options):
    status, expected = expected_output(values, **abi_options)
    if status < 0:
        return payload == b""
    if not isinstance(payload, (bytes, bytearray)) or len(payload) != status:
        return False
    n = values[0]
    expected_words = struct.unpack("<" + "d" * (status // 8), expected)
    observed_words = struct.unpack("<" + "d" * (status // 8), payload)
    nnz = int(expected_words[1])
    structural_word_count = 2 + (n + 1) + nnz
    if observed_words[:structural_word_count] != expected_words[:structural_word_count]:
        return False
    observed = observed_words[structural_word_count:]
    reference = expected_words[structural_word_count:]
    return all(math.isfinite(actual) and
               abs(actual - target) <= ABSOLUTE_TOLERANCE + RELATIVE_TOLERANCE * abs(target)
               for actual, target in zip(observed, reference))


def verify_result(values, result, output, **abi_options):
    status, _expected = expected_output(values, **abi_options)
    return result == status and validate_output(values, output, **abi_options)

