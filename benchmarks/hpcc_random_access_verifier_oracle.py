"""Independent sparse-state verifier for bounded HPCC RandomAccess."""

from __future__ import annotations

MAX_N = 256
MIN_N = 2
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (input_is_null or type(input_is_null) is not bool
            or not isinstance(values, (list, tuple))
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or len(values) != 1
            or type(values[0]) is not int):
        return -1

    size = values[0]
    if not MIN_N <= size <= MAX_N or size & (size - 1):
        return -1

    # Only entries that differ from their initial value are stored here.
    changed: dict[int, int] = {}
    state = 1
    for _ in range(size * 4):
        high_bit = state >> 63
        state = ((state << 1) & MASK64) ^ (7 if high_bit else 0)
        slot = state & (size - 1)
        previous = changed.get(slot, slot)
        updated = previous ^ state
        if updated == slot:
            changed.pop(slot, None)
        else:
            changed[slot] = updated

    digest = 0
    for slot in range(size):
        digest = (digest + (slot + 1) * changed.get(slot, slot)) & MASK64
    return digest & MASK63
