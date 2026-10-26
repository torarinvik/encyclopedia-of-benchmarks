"""Block-index rank1/select1 oracle for a bounded bit string."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_BITS = 63
MAX_QUERIES = 16
MAX_INPUT = 35
MAX_OUTPUT_BYTES = 128


def _parse(values: Sequence[int] | None) -> tuple[int, int, list[tuple[int, int]]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    bit_length, bits, query_count = values[:3]
    if not 1 <= bit_length <= MAX_BITS or bits < 0 or bits >> bit_length:
        return None
    if not 0 <= query_count <= MAX_QUERIES or len(values) != 3 + 2 * query_count:
        return None
    queries = []
    for offset in range(3, len(values), 2):
        opcode, index = values[offset:offset + 2]
        if opcode == 0 and not 1 <= index <= bit_length or opcode == 1 and not 1 <= index <= MAX_BITS + 1:
            return None
        if opcode not in (0, 1):
            return None
        queries.append((opcode, index))
    return bit_length, bits, queries


def _answers(bit_length: int, bits: int, queries: list[tuple[int, int]]) -> list[int]:
    block_count = (bit_length + 7) // 8
    block_prefix = [0] * (block_count + 1)
    for block in range(block_count):
        start = 8 * block
        end = min(bit_length, start + 8)
        block_prefix[block + 1] = block_prefix[block] + sum((bits >> pos) & 1 for pos in range(start, end))
    result = []
    for opcode, index in queries:
        if opcode == 0:
            full_blocks, remainder = divmod(index, 8)
            answer = block_prefix[full_blocks]
            start = 8 * full_blocks
            for pos in range(start, start + remainder):
                answer += (bits >> pos) & 1
            result.append(answer)
        else:
            block = 0
            while block < block_count and block_prefix[block + 1] < index:
                block += 1
            if block == block_count:
                result.append(-1)
                continue
            remaining = index - block_prefix[block]
            start = 8 * block
            end = min(bit_length, start + 8)
            selected = -1
            for pos in range(start, end):
                if (bits >> pos) & 1:
                    remaining -= 1
                    if remaining == 0:
                        selected = pos + 1
                        break
            result.append(selected)
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    bit_length, bits, queries = parsed
    payload = b"".join(struct.pack("<q", answer)
                       for answer in _answers(bit_length, bits, queries))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
