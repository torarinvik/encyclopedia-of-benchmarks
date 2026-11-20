"""Cox-de Boor basis recursion, independent of the local de Boor polygon."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_CONTROL_POINTS,
    MAX_DEGREE,
    MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH,
    OUTPUT_ERROR_RESULT,
    WORKSPACE_BYTES,
    _parse,
)


def _basis_span(degree: int, count: int, parameter: float,
                knots: Sequence[float]) -> int:
    """Select the basis interval independently from the primary helper."""
    if parameter == knots[count]:
        return count - 1
    span = degree
    # Advancing through equality selects the right-hand interval at a repeated knot.
    while span < count - 1 and parameter >= knots[span + 1]:
        span += 1
    return span


def cox_basis_value(degree: int, count: int, parameter: float,
                    knots: Sequence[float], controls: Sequence[float]) -> float:
    span = _basis_span(degree, count, parameter, knots)
    left = [0.0] * (degree + 1)
    right = [0.0] * (degree + 1)
    basis = [0.0] * (degree + 1)
    basis[0] = 1.0
    for order in range(1, degree + 1):
        left[order] = parameter - knots[span + 1 - order]
        right[order] = knots[span + order] - parameter
        saved = 0.0
        for index in range(order):
            denominator = right[index + 1] + left[order - index]
            quotient = 0.0 if denominator == 0.0 else basis[index] / denominator
            basis[index] = saved + right[index + 1] * quotient
            saved = left[order - index] * quotient
        basis[order] = saved
    return sum(controls[span - degree + index] * basis[index]
               for index in range(degree + 1))


def expected_output(values: Sequence[float] | None,
                    output_capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, []
    if (type(output_is_null) is not bool or output_is_null
            or type(output_capacity) is not int
            or output_capacity < MAX_OUTPUT_ELEMENTS):
        return OUTPUT_ERROR_RESULT, []
    return MAX_OUTPUT_ELEMENTS, [cox_basis_value(*parsed)]
