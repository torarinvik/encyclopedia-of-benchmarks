"""Closed-form independent reference for position-only Verlet trajectories."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None) -> tuple[int, int, int, tuple[int, ...]] | None:
    if (
        not isinstance(values, (tuple, list))
        or not 3 <= len(values) <= 33
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    count, first, second, *terms = values
    if count < 2 or count > 32 or len(terms) != count - 2:
        return None
    if first < -1024 or first > 1024 or second < -1024 or second > 1024:
        return None
    if any(term < -64 or term > 64 for term in terms):
        return None
    return count, first, second, tuple(terms)


def render(values: Sequence[int] | None) -> bytes | None:
    decoded = _decode(values)
    if decoded is None:
        return None
    count, first, second, terms = decoded
    trajectory: list[int] = []
    for index in range(count):
        position = first + index * (second - first)
        for term_index, term in enumerate(terms):
            weight = index - term_index - 1
            if weight > 0:
                position += weight * term
        trajectory.append(position)
    return b"".join(value.to_bytes(8, "little", signed=True) for value in trajectory)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null:
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (tuple, list))
        or input_length != len(values)
    ):
        return -1, b""
    output = render(values)
    if output is None:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
