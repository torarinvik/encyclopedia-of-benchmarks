"""Independent violation-trace oracle for the bounded BLR test profile."""

from __future__ import annotations

from collections.abc import Sequence

WORKSPACE_BYTES = 1024


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > 130:
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
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
    if any(point < 0 or point >= domain for point in tape):
        return -1, b""

    # Form the complete consistency trace, then retain only its source-visible prefix.
    failures = 0
    for round_index in range(q):
        x = tape[2 * round_index]
        y = tape[2 * round_index + 1]
        bad = table[x] ^ table[y] ^ table[x ^ y]
        failures |= (bad & 1) << round_index
    first_failure = next((i for i in range(q) if (failures >> i) & 1), None)
    rounds = q if first_failure is None else first_failure + 1
    accepted = int(first_failure is None)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or capacity is not None and capacity < 24:
        return -2, b""
    payload = b"".join(value.to_bytes(8, "little", signed=True)
                        for value in (accepted, rounds, 3 * rounds))
    return 24, payload
