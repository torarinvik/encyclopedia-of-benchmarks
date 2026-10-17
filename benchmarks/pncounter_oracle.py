"""Oracle for the bounded source-faithful Java PN-counter trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 16
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 5 + MAX_OPERATIONS
MAX_OUTPUT_WORDS = 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2

_COMPARE_PAIRS = ((0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1))


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return encoded operation records or an ABI error with no output."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if len(values) < 5 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID_RESULT, b""

    node_count, *header = values[:5]
    if not 1 <= node_count <= MAX_NODES:
        return INVALID_RESULT, b""
    ids = header[:3]
    operation_count = header[3]
    if any(type(node_id) is not int or not 0 <= node_id < node_count for node_id in ids):
        return INVALID_RESULT, b""
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    if len(values) != 5 + operation_count:
        return INVALID_RESULT, b""

    p_state = [[0] * node_count for _ in range(3)]
    n_state = [[0] * node_count for _ in range(3)]
    records: list[int] = []

    for opcode in values[5:]:
        if not 0 <= opcode <= 20:
            return INVALID_RESULT, b""
        if opcode < 6:
            counter, is_negative = divmod(opcode, 2)
            if is_negative:
                n_state[counter][ids[counter]] += 1
            else:
                p_state[counter][ids[counter]] += 1
            records.append(opcode)
        elif opcode < 9:
            counter = opcode - 6
            value = sum(p_state[counter]) - sum(n_state[counter])
            records.extend((opcode, value))
        elif opcode < 15:
            pair_index = opcode - 9
            target, source = _COMPARE_PAIRS[pair_index]
            for node in range(node_count):
                p_state[target][node] = max(p_state[target][node], p_state[source][node])
                n_state[target][node] = max(n_state[target][node], n_state[source][node])
            records.append(opcode)
        else:
            left, right = _COMPARE_PAIRS[opcode - 15]
            result = all(
                not (p_state[left][node] > p_state[right][node]
                     and n_state[left][node] > n_state[right][node])
                for node in range(node_count)
            )
            records.extend((opcode, int(result)))

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", word) for word in records)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
