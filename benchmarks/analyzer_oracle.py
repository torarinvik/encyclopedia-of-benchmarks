"""Independent oracle for the bounded FreeBench RAW-trace analysis core."""

from __future__ import annotations

from collections.abc import Sequence

MAX_EVENTS = 64
MAX_EPOCH = 15
MAX_ADDRESS = 255
MAX_INPUT_LENGTH = 1 + 3 * MAX_EVENTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int]) -> int:
    """Count loads whose latest earlier write belongs to a prior epoch.

    This oracle uses a per-address last-writer map, independently of the
    ports' bounded scan through prior trace rows.
    """
    if (not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    event_count = values[0]
    if event_count < 0 or event_count > MAX_EVENTS or len(values) != 1 + 3 * event_count:
        return INVALID_RESULT

    latest_writer: dict[int, int] = {}
    conflicts = 0
    previous_epoch = 0
    for event_index in range(event_count):
        epoch, opcode, address = values[1 + 3 * event_index:4 + 3 * event_index]
        if (epoch < previous_epoch or epoch < 0 or epoch > MAX_EPOCH
                or opcode not in (0, 1) or address < 0 or address > MAX_ADDRESS):
            return INVALID_RESULT
        previous_epoch = epoch
        if opcode == 0:
            latest_writer[address] = epoch
        elif address in latest_writer and latest_writer[address] < epoch:
            conflicts += 1
    return conflicts
