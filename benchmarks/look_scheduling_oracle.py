"""Independent oracle for the pinned Java LOOK disk-scheduling contract."""

from __future__ import annotations

MAX_REQUESTS = 4096
MAX_TRACK = 256
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
MAX_INPUT_LENGTH = MAX_REQUESTS + 4
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def _fnv_i64_record(values: list[int]) -> int:
    digest = FNV_OFFSET
    for value in values:
        bits = value & MASK64
        for shift in range(0, 64, 8):
            digest = ((digest ^ ((bits >> shift) & 0xFF)) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the one-call serviced-request/state hash, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or not 4 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return -1

    max_track, start, direction, count = values[:4]
    if not 1 <= max_track <= MAX_TRACK or not 0 <= start < max_track or direction not in (0, 1):
        return -1
    if not 0 <= count <= MAX_REQUESTS or len(values) != count + 4:
        return -1
    requests = values[4:]
    if any(not INT32_MIN <= request <= INT32_MAX for request in requests):
        return -1

    lower = [request for request in requests if 0 <= request < start]
    upper = [request for request in requests if start <= request < max_track]
    lower.sort()
    upper.sort()
    if direction == 1:
        route = upper + list(reversed(lower))
        final_direction = 0
    else:
        route = list(reversed(lower)) + upper
        final_direction = 1

    farthest = max((request for request in requests if 0 <= request < max_track), default=0)
    record = [len(route), *route, final_direction, farthest, start]
    return _fnv_i64_record(record)
