"""Oracle for the stable key-only TimSorter workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ITEMS = 512
MIN_KEY = -1_000
MAX_KEY = 1_000
MAX_VALID_INPUT_VALUES = 1_025
MAX_PARSEABLE_INPUT_VALUES = 1_026
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
HASH_MULTIPLIER = 1_000_003
HASH_MODULUS = 1_000_000_007


def expected_result(values: Sequence[int] | None) -> int:
    """Return an order-sensitive checksum, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or len(values) < 1
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT

    count = values[0]
    if not 0 <= count <= MAX_ITEMS or len(values) != 1 + 2 * count:
        return INVALID_RESULT

    items: list[tuple[int, int]] = []
    seen_tags: set[int] = set()
    cursor = 1
    for _ in range(count):
        key, tag = values[cursor : cursor + 2]
        cursor += 2
        if not MIN_KEY <= key <= MAX_KEY or not 0 <= tag < count or tag in seen_tags:
            return INVALID_RESULT
        seen_tags.add(tag)
        items.append((key, tag))

    # Python's sort is stable; only the key participates in the source comparer.
    ordered = sorted(items, key=lambda item: item[0])
    checksum = 0
    for key, tag in ordered:
        token = (key - MIN_KEY) * (MAX_ITEMS + 1) + tag + 1
        checksum = (checksum * HASH_MULTIPLIER + token) % HASH_MODULUS
    return checksum
