"""Independent oracle for the bounded Sierpinski triangle turtle trace."""

from __future__ import annotations

from collections.abc import Sequence

MIN_DEPTH = 0
MAX_DEPTH = 4
VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 11_616
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _i64_le(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def _midpoint(first: tuple[float, float], second: tuple[float, float]) -> tuple[float, float]:
    return ((first[0] + second[0]) / 2, (first[1] + second[1]) / 2)


def expected_output(
    values: Sequence[int], capacity: int | None = None, output_is_null: bool = False
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (list, tuple))
        or not VALID_INPUT_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""
    if len(values) != VALID_INPUT_LENGTH or not MIN_DEPTH <= values[0] <= MAX_DEPTH:
        return INVALID_RESULT, b""

    segments: list[tuple[int, int, int, int]] = []

    def draw(
        first: tuple[float, float],
        second: tuple[float, float],
        third: tuple[float, float],
        depth: int,
    ) -> None:
        segments.extend(
            (
                (first[0], first[1], second[0], second[1]),
                (second[0], second[1], third[0], third[1]),
                (third[0], third[1], first[0], first[1]),
            )
        )
        if depth == 0:
            return
        first_second = _midpoint(first, second)
        first_third = _midpoint(first, third)
        second_third = _midpoint(second, third)
        draw(first, first_second, first_third, depth - 1)
        draw(second, first_second, second_third, depth - 1)
        draw(third, second_third, first_third, depth - 1)

    draw((-175.0, -125.0), (0.0, 175.0), (175.0, -125.0), values[0])
    flat = [int(coordinate * 16) for segment in segments for coordinate in segment]
    output = b"".join(_i64_le(value) for value in flat)
    if output_is_null or (
        capacity is not None and (type(capacity) is not int or capacity < len(output))
    ):
        return CAPACITY_ERROR, b""
    return len(output), output


def expected_result(
    values: Sequence[int], capacity: int | None = None, output_is_null: bool = False
) -> tuple[int, bytes]:
    return expected_output(values, capacity, output_is_null)
