"""Exact bounded oracle for the pinned Java CircularScanScheduling behavior."""

from __future__ import annotations

from typing import Sequence

MAX_REQUESTS = 64
MAX_DISK_SIZE = 128
MIN_REQUEST_VALUE = -128
MAX_REQUEST_VALUE = 127
MAX_INPUT_LENGTH = 4 + MAX_REQUESTS
MAX_OUTPUT_BYTES = MAX_REQUESTS


def expected_output(values: Sequence[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    disk_size, start, moving_up, request_count = values[:4]
    if not 1 <= disk_size <= MAX_DISK_SIZE or not 0 <= start < disk_size:
        return -1, b""
    if moving_up not in (0, 1) or not 0 <= request_count <= MAX_REQUESTS:
        return -1, b""
    if len(values) != 4 + request_count:
        return -1, b""
    requests = values[4:]
    if any(not MIN_REQUEST_VALUE <= request <= MAX_REQUEST_VALUE for request in requests):
        return -1, b""

    ordered_requests = sorted(requests)
    if moving_up:
        first = [request for request in ordered_requests if start <= request < disk_size]
        wrapped = [request for request in ordered_requests if request < start]
        ordered = first + wrapped
    else:
        first = [request for request in reversed(ordered_requests) if request <= start]
        wrapped = [request for request in reversed(ordered_requests) if request > start]
        ordered = first + wrapped

    output = bytes(request & 0xFF for request in ordered)
    return len(output), output
