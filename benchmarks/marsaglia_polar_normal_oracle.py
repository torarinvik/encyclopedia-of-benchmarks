"""High-precision oracle for the bounded Marsaglia polar transform."""

from __future__ import annotations

from collections.abc import Sequence
from decimal import Decimal, localcontext
import math

MAX_DRAWS = 128
MAX_ATTEMPTS = 64
MAX_INPUT_LENGTH = 2 + MAX_DRAWS
OUTPUT_ELEMENTS = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2
DRAW_SCALE = 1 << 31
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _bounded_integer(value: object, minimum: int, maximum: int) -> int | None:
    if type(value) not in (int, float):
        return None
    numeric = float(value)
    if not math.isfinite(numeric) or numeric != math.trunc(numeric):
        return None
    if numeric < minimum or numeric > maximum:
        return None
    return int(numeric)


def _validated_input(values: Sequence[int | float] | None,
                     input_length: int | None = None) -> tuple[int, int, list[int]] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    draw_count = _bounded_integer(values[0], 2, MAX_DRAWS)
    attempt_cap = _bounded_integer(values[1], 1, MAX_ATTEMPTS)
    if draw_count is None or attempt_cap is None:
        return None
    if draw_count % 2 != 0 or len(values) != 2 + draw_count or draw_count < 2 * attempt_cap:
        return None
    draws: list[int] = []
    for value in values[2:]:
        draw = _bounded_integer(value, 0, (1 << 32) - 1)
        if draw is None:
            return None
        draws.append(draw)
    return draw_count, attempt_cap, draws


def _solve(values: Sequence[int | float] | None,
           input_length: int | None = None) -> tuple[int, list[float], int | None]:
    parsed = _validated_input(values, input_length)
    if parsed is None:
        return INVALID_RESULT, [], None
    _, attempt_cap, draws = parsed

    with localcontext() as context:
        context.prec = 80
        denominator = Decimal(DRAW_SCALE)
        for attempt in range(attempt_cap):
            first_draw = Decimal(draws[2 * attempt])
            second_draw = Decimal(draws[2 * attempt + 1])
            u1 = first_draw / denominator - 1
            u2 = second_draw / denominator - 1
            radius_squared = u1 * u1 + u2 * u2
            consumed = 2 * (attempt + 1)
            if radius_squared <= 0 or radius_squared >= 1:
                continue
            scale = (-Decimal(2) * radius_squared.ln() / radius_squared).sqrt()
            return 2, [float(u1 * scale), float(u2 * scale)], consumed
    return INVALID_RESULT, [], 2 * attempt_cap


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return ``(status, pair)`` for ``[draw_count, attempt_cap, draws...]``."""
    status, pair, _ = _solve(values, input_length)
    if status < 0:
        return status, []
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, []
    capacity = OUTPUT_ELEMENTS if output_capacity is None else output_capacity
    if type(capacity) is not int or capacity < 0:
        return OUTPUT_ERROR, []
    if output_is_null or capacity < OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, []
    return OUTPUT_ELEMENTS, pair


def expected_result(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the ABI status for a supplied tape and output capacity."""
    return expected_output(values, output_capacity, output_is_null, input_length)[0]


def draws_consumed(values: Sequence[int | float] | None,
                   input_length: int | None = None) -> int | None:
    """Return tape draws used, or ``None`` for malformed input."""
    status, _, consumed = _solve(values, input_length)
    if consumed is None:
        return None
    return consumed


def certificate_holds(values: Sequence[int | float] | None,
                      candidate: Sequence[float]) -> bool:
    """Check both output components against the high-precision transform."""
    status, expected, _ = _solve(values)
    if status < 0 or not isinstance(candidate, (list, tuple)) or len(candidate) != 2:
        return False
    for actual, target in zip(candidate, expected):
        if type(actual) not in (int, float) or not math.isfinite(float(actual)):
            return False
        if abs(float(actual) - target) > ABSOLUTE_TOLERANCE + RELATIVE_TOLERANCE * abs(target):
            return False
    return True
