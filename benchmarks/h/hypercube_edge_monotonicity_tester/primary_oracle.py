"""Source-ordered hypercube edge-tester oracle for a fixed random tape."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 6
MAX_Q = 32
MAX_VALID_INPUT_WORDS = 130
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 24
WORKSPACE_BYTES = 1024


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_WORDS
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    domain = 1 << n
    if len(values) != 2 + domain + 2 * q:
        return None
    table = values[2:2 + domain]
    if any(bit not in (0, 1) for bit in table):
        return None
    tape = values[2 + domain:]
    for at in range(0, 2 * q, 2):
        if not 0 <= tape[at] < domain or not 0 <= tape[at + 1] < n:
            return None
    return n, q, table, tape


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, q, table, tape = parsed
    rounds = 0
    accepted = 1
    for at in range(0, 2 * q, 2):
        vertex, coordinate = tape[at], tape[at + 1]
        bit = 1 << coordinate
        lower = vertex & ~bit
        upper = lower | bit
        rounds += 1
        if table[lower] > table[upper]:
            accepted = 0
            break
    payload = struct.pack("<qqq", accepted, rounds, 2 * rounds)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
