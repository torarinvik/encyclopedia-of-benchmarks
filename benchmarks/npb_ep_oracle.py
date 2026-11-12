"""High-precision oracle for the bounded NPB EP kernel profile."""

from __future__ import annotations

from collections.abc import Sequence
from decimal import Decimal, localcontext
import math

MAX_PAIRS = 4096
MAX_INPUT_LENGTH = 2
HISTOGRAM_BINS = 10
OUTPUT_ELEMENTS = HISTOGRAM_BINS + 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MODULUS = 1 << 46
MODULUS_MASK = MODULUS - 1
MULTIPLIER = 5 ** 13
NPB_EP_SEED = 271_828_183
MAX_SEED = MODULUS - 1
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


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
                input_length: int | None = None) -> tuple[int, int] | None:
    if not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    pair_count = _integer(values[0], 1, MAX_PAIRS)
    seed = _integer(values[1], 1, MAX_SEED)
    if pair_count is None or seed is None:
        return None
    return pair_count, seed


def _solve(values: Sequence[int | float] | None,
           input_length: int | None = None) -> tuple[int, list[float], int | None]:
    parsed = _validated(values, input_length)
    if parsed is None:
        return INVALID_RESULT, [], None
    pair_count, state = parsed
    counts = [0] * HISTOGRAM_BINS
    sum_x = Decimal(0)
    sum_y = Decimal(0)
    with localcontext() as context:
        context.prec = 80
        modulus = Decimal(MODULUS)
        for _ in range(pair_count):
            state = (state * MULTIPLIER) & MODULUS_MASK
            x = Decimal(2) * Decimal(state) / modulus - 1
            state = (state * MULTIPLIER) & MODULUS_MASK
            y = Decimal(2) * Decimal(state) / modulus - 1
            radius_squared = x * x + y * y
            if radius_squared <= 0 or radius_squared > 1:
                continue
            scale = (-Decimal(2) * radius_squared.ln() / radius_squared).sqrt()
            normal_x, normal_y = x * scale, y * scale
            extent = max(abs(normal_x), abs(normal_y))
            if extent < HISTOGRAM_BINS:
                counts[int(extent)] += 1
            sum_x += normal_x
            sum_y += normal_y
    output = [float(count) for count in counts]
    output.extend((float(sum_x), float(sum_y)))
    return OUTPUT_ELEMENTS, output, 2 * pair_count


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return ``(status, ten bins followed by x/y sums)`` for the profile."""
    status, output, _ = _solve(values, input_length)
    if status < 0:
        return status, []
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, []
    capacity = OUTPUT_ELEMENTS if output_capacity is None else output_capacity
    if type(capacity) is not int or capacity < 0:
        return OUTPUT_ERROR, []
    if output_is_null or capacity < OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, []
    return OUTPUT_ELEMENTS, output


def expected_result(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return only the ABI status for a bounded EP input."""
    return expected_output(values, output_capacity, output_is_null, input_length)[0]


def draws_consumed(values: Sequence[int | float] | None,
                   input_length: int | None = None) -> int | None:
    """Return the two LCG transitions per candidate pair, when valid."""
    status, _, consumed = _solve(values, input_length)
    return consumed if status >= 0 else None


def certificate_holds(values: Sequence[int | float] | None,
                      candidate: Sequence[float]) -> bool:
    """Check exact histogram bins and tolerant coordinate sums."""
    status, expected, _ = _solve(values)
    if status < 0 or not isinstance(candidate, (list, tuple)) or len(candidate) != OUTPUT_ELEMENTS:
        return False
    for index in range(HISTOGRAM_BINS):
        if type(candidate[index]) not in (int, float) or candidate[index] != expected[index]:
            return False
    for index in (HISTOGRAM_BINS, HISTOGRAM_BINS + 1):
        actual, target = candidate[index], expected[index]
        if (type(actual) not in (int, float) or not math.isfinite(float(actual))
                or abs(float(actual) - target)
                > ABSOLUTE_TOLERANCE + RELATIVE_TOLERANCE * abs(target)):
            return False
    return True
