"""Independent signed-integer ordering reference."""

from __future__ import annotations

from collections.abc import Sequence


def expected_result(values: Sequence[int]) -> list[int]:
    return sorted(values)
