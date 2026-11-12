"""Set-based oracle for the bounded dynamic predecessor problem."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 4096
MAX_QUERIES = 512
MAX_WORDS = (MAX_N + 63) // 64
MAX_INPUT_LENGTH = 2 + MAX_WORDS + 2 * MAX_QUERIES
MAX_OUTPUT_BYTES = MAX_QUERIES * 8


def _parse(values: Sequence[int] | None) -> tuple[int, list[int], list[tuple[int, int]]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, query_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= query_count <= MAX_QUERIES:
        return None
    word_count = (n + 63) // 64
    if len(values) != 2 + word_count + 2 * query_count:
        return None
    words = [value & ((1 << 64) - 1) for value in values[2:2 + word_count]]
    remainder = n % 64
    if remainder and words[-1] >> remainder:
        return None
    queries = []
    for offset in range(2 + word_count, len(values), 2):
        opcode, key = values[offset:offset + 2]
        if opcode not in (0, 1, 2, 3, 4) or not 0 <= key < n:
            return None
        queries.append((opcode, key))
    return n, words, queries


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, words, queries = parsed
    members = {index for index in range(n) if words[index // 64] >> (index % 64) & 1}
    answers: list[int] = []
    for opcode, key in queries:
        if opcode == 0:
            members.add(key)
        elif opcode == 1:
            members.discard(key)
        elif opcode == 2:
            answers.append(int(key in members))
        elif opcode == 3:
            answers.append(min((value for value in members if value >= key), default=-1))
        else:
            answers.append(max((value for value in members if value <= key), default=-1))
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
