"""Direct arithmetic reference for a deterministic virtual-time token bucket."""

from __future__ import annotations

from collections.abc import Sequence

MAX_CAPACITY = 64
MAX_REFILL_RATE = 32
MAX_REQUESTS = 63
MAX_ELAPSED_TICKS = 256
MAX_VALID_INPUT_LENGTH = 3 + MAX_REQUESTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual = len(values) if input_length is None else input_length
    if type(actual) is not int or actual != len(values) or not 3 <= actual <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    capacity, refill_rate, request_count = values[:3]
    if not 0 <= capacity <= MAX_CAPACITY or not 0 <= refill_rate <= MAX_REFILL_RATE:
        return None
    if not 0 <= request_count <= MAX_REQUESTS or actual != 3 + request_count:
        return None
    elapsed = tuple(values[3:])
    if any(not 0 <= ticks <= MAX_ELAPSED_TICKS for ticks in elapsed):
        return None
    return capacity, refill_rate, elapsed


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    capacity, refill_rate, elapsed = parsed
    tokens = capacity
    allowed = 0
    for index, ticks in enumerate(elapsed):
        tokens = min(capacity, tokens + ticks * refill_rate)
        if tokens > 0:
            allowed |= 1 << index
            tokens -= 1
    return allowed
