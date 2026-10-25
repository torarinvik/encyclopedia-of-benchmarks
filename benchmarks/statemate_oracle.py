"""Oracle for Embench-IoT's fixed no-stimulus Statemate workload profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_RUNS = 256
BITLIST_BYTES = 64
STATE_BYTES = 16
TIMER_BYTES = 12
OUTPUT_BYTES = BITLIST_BYTES + STATE_BYTES + TIMER_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
DEFAULT_STATES = (0, 0, 0, 3, 2, 1, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1)


def _settle_once() -> bytes:
    bitlist = [0] * BITLIST_BYTES
    states = [0] * STATE_BYTES
    timers = [0, 0, 0]

    stable = False
    while not stable:
        stable = True
        for index, target in enumerate(DEFAULT_STATES):
            if states[index] == 0 and target != 0:
                states[index] = target
                stable = False

    # The source's fixed initialization and no-stimulus control path leaves
    # its sixth Bitlist entry set; the remaining entries and timer words are 0.
    bitlist[5] = 1
    timer_bytes = b"".join(value.to_bytes(4, "little") for value in timers)
    return bytes(bitlist + states) + timer_bytes


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the source verifier's 64-entry Bitlist and 19-state snapshot."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0))
        or (input_length is not None and (type(input_length) is not int or input_length < 0))
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if (
        len(values) != 1
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or not 1 <= values[0] <= MAX_RUNS
    ):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""

    snapshot = b""
    for _ in range(values[0]):
        snapshot = _settle_once()
    return len(snapshot), snapshot
