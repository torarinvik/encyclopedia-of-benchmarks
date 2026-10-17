"""Independent bounded oracle for the pinned Java SSF scheduling behavior."""

from __future__ import annotations

from typing import Sequence

MAX_REQUESTS = 64
MAX_TRACK = 255
MAX_INPUT_LENGTH = 2 + MAX_REQUESTS
MAX_OUTPUT_BYTES = MAX_REQUESTS


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (result, output bytes) for one bounded SSF call.

    Invalid input takes precedence over output-pointer and capacity errors.
    Ties retain the earliest request in the still-pending input order.
    """
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1, b""

    initial_track, request_count = values[:2]
    if not 0 <= initial_track <= MAX_TRACK:
        return -1, b""
    if not 0 <= request_count <= MAX_REQUESTS or len(values) != 2 + request_count:
        return -1, b""
    requests = values[2:]
    if any(not 0 <= request <= MAX_TRACK for request in requests):
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null:
        return -2, b""

    pending = list(requests)
    current = initial_track
    ordered: list[int] = []
    while pending:
        best_index = 0
        best_distance = abs(current - pending[0])
        for index in range(1, len(pending)):
            distance = abs(current - pending[index])
            if distance < best_distance:
                best_index = index
                best_distance = distance
        current = pending.pop(best_index)
        ordered.append(current)

    output = bytes(ordered)
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
