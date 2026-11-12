"""High-precision oracle for the bounded Cartesian Box–Muller transform."""

from __future__ import annotations

from collections.abc import Sequence
from decimal import Decimal, localcontext
import math

MAX_PAIRS = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_PAIRS
MAX_DRAW = (1 << 32) - 1
OUTPUT_ELEMENTS = 2 * MAX_PAIRS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
DRAW_SCALE = 1 << 32
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
_PI = Decimal(
    "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117068"
)


def _integer(value: object, minimum: int, maximum: int) -> int | None:
    if type(value) not in (int, float):
        return None
    numeric = float(value)
    if not math.isfinite(numeric) or numeric != math.trunc(numeric):
        return None
    if not minimum <= numeric <= maximum:
        return None
    return int(numeric)


def _validated(values: Sequence[int | float] | None,
                input_length: int | None = None) -> tuple[int, list[int]] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    pair_count = _integer(values[0], 1, MAX_PAIRS)
    if pair_count is None or len(values) != 1 + 2 * pair_count:
        return None
    draws: list[int] = []
    for value in values[1:]:
        draw = _integer(value, 0, MAX_DRAW)
        if draw is None:
            return None
        draws.append(draw)
    return pair_count, draws


def _sin_cos(angle: Decimal) -> tuple[Decimal, Decimal]:
    """Evaluate sine and cosine with convergent Decimal Taylor recurrences."""
    two_pi = 2 * _PI
    if angle > _PI:
        angle -= two_pi
    square = angle * angle
    sine = sine_term = angle
    cosine = cosine_term = Decimal(1)
    threshold = Decimal(1).scaleb(-88)
    for index in range(1, 160):
        sine_term *= -square / Decimal((2 * index) * (2 * index + 1))
        cosine_term *= -square / Decimal((2 * index - 1) * (2 * index))
        sine += sine_term
        cosine += cosine_term
        if abs(sine_term) < threshold and abs(cosine_term) < threshold:
            break
    return sine, cosine


def _solve(values: Sequence[int | float] | None,
           input_length: int | None = None) -> tuple[int, list[float], int | None]:
    parsed = _validated(values, input_length)
    if parsed is None:
        return INVALID_RESULT, [], None
    pair_count, draws = parsed
    output: list[float] = []
    with localcontext() as context:
        context.prec = 90
        denominator = Decimal(DRAW_SCALE)
        for pair_index in range(pair_count):
            radial_draw = Decimal(draws[2 * pair_index])
            angular_draw = Decimal(draws[2 * pair_index + 1])
            radial_uniform = (radial_draw + 1) / denominator
            angular_uniform = angular_draw / denominator
            radius = (-2 * radial_uniform.ln()).sqrt()
            sine, cosine = _sin_cos(2 * _PI * angular_uniform)
            output.extend((float(radius * cosine), float(radius * sine)))
    return len(output), output, 2 * pair_count


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return ``(status, samples)`` for ``[pair_count, draws...]``."""
    status, output, _ = _solve(values, input_length)
    if status < 0:
        return status, []
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, []
    capacity = status if output_capacity is None else output_capacity
    if type(capacity) is not int or capacity < 0:
        return OUTPUT_ERROR, []
    if output_is_null or capacity < status:
        return OUTPUT_ERROR, []
    return status, output


def expected_result(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return only the ABI status for a supplied tape."""
    return expected_output(values, output_capacity, output_is_null, input_length)[0]


def draws_consumed(values: Sequence[int | float] | None,
                   input_length: int | None = None) -> int | None:
    """Return tape draws used, or ``None`` when the tape is malformed."""
    status, _, consumed = _solve(values, input_length)
    return consumed if status >= 0 else None


def certificate_holds(values: Sequence[int | float] | None,
                      candidate: Sequence[float]) -> bool:
    """Check output samples against the high-precision transform."""
    status, expected, _ = _solve(values)
    if status < 0 or not isinstance(candidate, (list, tuple)) or len(candidate) != status:
        return False
    for actual, target in zip(candidate, expected):
        if type(actual) not in (int, float) or not math.isfinite(float(actual)):
            return False
        if abs(float(actual) - target) > ABSOLUTE_TOLERANCE + RELATIVE_TOLERANCE * abs(target):
            return False
    return True
