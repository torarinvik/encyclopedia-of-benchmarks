"""Independent built-in-order reference for signed-i64 arrays."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import I64_MAX, I64_MIN, MAX_LENGTH
except ImportError:  # Direct invocation from the package directory.
    from primary_oracle import I64_MAX, I64_MIN, MAX_LENGTH  # type: ignore[no-redef]


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        raise ValueError("external quicksort accepts at most 1024 signed 64-bit values")
    return sorted(values)
