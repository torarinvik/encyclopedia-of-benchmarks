"""Exact bounded oracle for the pinned Java CircularLookScheduling behavior."""

from __future__ import annotations

from typing import Sequence

MAX_REQUESTS = 64
MAX_CYLINDER_COUNT = 128
MAX_REQUEST_VALUE = 255
MIN_REQUEST_VALUE = -128
MAX_INPUT_LENGTH = 4 + MAX_REQUESTS
MAX_OUTPUT_BYTES = MAX_REQUESTS


def expected_output(values: Sequence[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    max_cylinder_count, start_position, moving_up, request_count = values[:4]
    if not 1 <= max_cylinder_count <= MAX_CYLINDER_COUNT:
        return -1, b""
    if not 0 <= start_position < max_cylinder_count or moving_up not in (0, 1):
        return -1, b""
    if not 0 <= request_count <= MAX_REQUESTS or len(values) != 4 + request_count:
        return -1, b""

    requests = values[4:]
    if any(not MIN_REQUEST_VALUE <= request <= MAX_REQUEST_VALUE for request in requests):
        return -1, b""

    up_requests = sorted(request for request in requests
                         if start_position < request < max_cylinder_count)
    down_requests = sorted(request for request in requests
                           if 0 <= request < start_position)

    # Preserve the pinned source's exact branch order. Its downward branch
    # reverses both partitions, so the wrapped upper partition is descending.
    ordered = (up_requests + down_requests if moving_up
               else list(reversed(down_requests)) + list(reversed(up_requests)))
    output = bytes(ordered)
    return len(output), output
