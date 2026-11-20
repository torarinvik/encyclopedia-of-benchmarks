"""Independent full-violation-trace reference for the hypercube edge tester."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALID_INPUT_WORDS = 130
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 24
WORKSPACE_BYTES = 1024


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_WORDS
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    n, q = values[0], values[1]
    if not 1 <= n <= 6 or not 1 <= q <= 32:
        return -1, b""
    domain = 1 << n
    table_end = 2 + domain
    if len(values) != table_end + 2 * q:
        return -1, b""
    table = values[2:table_end]
    tape = values[table_end:]
    if any(bit not in (0, 1) for bit in table):
        return -1, b""
    if any(tape[at] < 0 or tape[at] >= domain or tape[at + 1] < 0 or tape[at + 1] >= n
           for at in range(0, 2 * q, 2)):
        return -1, b""

    violations = []
    for at in range(0, 2 * q, 2):
        vertex, coordinate = tape[at], tape[at + 1]
        lower = vertex & ~(1 << coordinate)
        upper = lower | (1 << coordinate)
        violations.append(table[lower] > table[upper])
    first = next((index for index, failed in enumerate(violations) if failed), None)
    rounds = q if first is None else first + 1
    accepted = int(first is None)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or capacity is not None and capacity < 24:
        return -2, b""
    payload = b"".join(value.to_bytes(8, "little", signed=True)
                        for value in (accepted, rounds, 2 * rounds))
    return 24, payload
