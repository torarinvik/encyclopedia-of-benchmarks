"""Independent sorted-multiset oracle for interval-heap trace behavior."""

from __future__ import annotations

import bisect
import struct
from collections.abc import Sequence

MAX_WORDS = 322
MAX_SEED = 64
MAX_STEPS = 128
LOWER = -(1 << 31)
UPPER = (1 << 31) - 1


def _frame(raw: Sequence[int] | None):
    if not isinstance(raw, (list, tuple)) or len(raw) < 2 or len(raw) > MAX_WORDS:
        return None
    for word in raw:
        if type(word) is not int or not -(1 << 63) <= word < (1 << 63):
            return None
    seed_size = raw[0]
    if seed_size < 0 or seed_size > MAX_SEED or len(raw) < seed_size + 2:
        return None
    steps = raw[seed_size + 1]
    if steps < 0 or steps > MAX_STEPS or len(raw) != seed_size + 2 + steps * 2:
        return None
    seed = list(raw[1:seed_size + 1])
    if any(number < LOWER or number > UPPER for number in seed):
        return None
    actions = []
    cursor = seed_size + 2
    for _ in range(steps):
        code, data = raw[cursor], raw[cursor + 1]
        cursor += 2
        if code not in range(6):
            return None
        if code == 0:
            if not LOWER <= data <= UPPER:
                return None
        elif data != 0:
            return None
        actions.append((code, data))
    return seed, actions


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0 or input_length > MAX_WORDS):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    parsed = _frame(values)
    if parsed is None:
        return -1, b""

    seed, actions = parsed
    ordered = sorted(seed)
    log: list[int] = []
    for code, data in actions:
        if code == 0:
            bisect.insort(ordered, data)
        elif code == 1 or code == 2:
            if not ordered:
                return -1, b""
            log.append(ordered[0] if code == 1 else ordered[-1])
        elif code == 3 or code == 4:
            if not ordered:
                return -1, b""
            index = 0 if code == 3 else len(ordered) - 1
            log.append(ordered.pop(index))
        else:
            log.append(len(ordered))

    result_words = [len(log), *log, len(ordered), *ordered]
    packed = b"".join(int(word).to_bytes(8, "little", signed=True) for word in result_words)
    if output_is_null or capacity is not None and len(packed) > capacity:
        return -2, b""
    return len(packed), packed
