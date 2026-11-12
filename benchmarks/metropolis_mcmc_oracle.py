"""Independent reference for a deterministic bounded Metropolis chain."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_STATES = 8
MAX_STEPS = 64
MIN_TEMPERATURE = 0.001
MAX_TEMPERATURE = 1000.0
MAX_ABS_ENERGY = 1_000_000.0
MAX_INPUT_LENGTH = 4 + MAX_STATES + 2 * MAX_STEPS
MAX_OUTPUT_ELEMENTS = MAX_STEPS + 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 0.0
RELATIVE_TOLERANCE = 0.0


def _number(value: object) -> float | None:
    if type(value) not in (int, float):
        return None
    try:
        numeric = float(value)
    except (OverflowError, ValueError):
        return None
    return numeric if math.isfinite(numeric) else None


def _exact_integer(value: object, minimum: int, maximum: int) -> int | None:
    numeric = _number(value)
    if numeric is None or not numeric.is_integer() or not minimum <= numeric <= maximum:
        return None
    return int(numeric)


def _trace(values: Sequence[int | float] | None,
           input_length: int | None = None) -> tuple[int, list[float]]:
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, []
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, []

    state_count = _exact_integer(values[0], 1, MAX_STATES)
    step_count = _exact_integer(values[1], 0, MAX_STEPS)
    if state_count is None or step_count is None:
        return INVALID_RESULT, []
    initial_state = _exact_integer(values[2], 0, state_count - 1)
    temperature = _number(values[3])
    if (initial_state is None or temperature is None
            or not MIN_TEMPERATURE <= temperature <= MAX_TEMPERATURE
            or len(values) != 4 + state_count + 2 * step_count):
        return INVALID_RESULT, []

    energies: list[float] = []
    for value in values[4:4 + state_count]:
        energy = _number(value)
        if energy is None or abs(energy) > MAX_ABS_ENERGY:
            return INVALID_RESULT, []
        energies.append(energy)

    proposals: list[int] = []
    proposal_start = 4 + state_count
    for value in values[proposal_start:proposal_start + step_count]:
        proposal = _exact_integer(value, 0, state_count - 1)
        if proposal is None:
            return INVALID_RESULT, []
        proposals.append(proposal)

    uniforms: list[float] = []
    uniform_start = proposal_start + step_count
    for value in values[uniform_start:]:
        uniform = _number(value)
        if uniform is None or not 0.0 <= uniform < 1.0:
            return INVALID_RESULT, []
        uniforms.append(uniform)

    chain = [float(initial_state)]
    state = initial_state
    for proposal, uniform in zip(proposals, uniforms):
        delta = (energies[proposal] - energies[state]) / temperature
        if delta <= 0.0 or uniform < math.exp(-delta):
            state = proposal
        chain.append(float(state))
    return len(chain), chain


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return ``(status, trace)`` for the packed state/energy/proposal tape."""
    status, chain = _trace(values, input_length)
    if status < 0:
        return status, []
    capacity = MAX_OUTPUT_ELEMENTS if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return OUTPUT_ERROR, []
    if output_is_null or capacity < status:
        return OUTPUT_ERROR, []
    return status, chain


def expected_result(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the ABI status for a bounded proposal tape."""
    return expected_output(values, output_capacity, output_is_null, input_length)[0]

