"""Exhaustive hidden-path Baum–Welch reference for bounded HMM profiles."""

from __future__ import annotations

import itertools
import math
from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_SEQUENCE_LENGTH,
    MAX_STATES,
    MAX_SYMBOLS,
    MIN_PROBABILITY,
    OUTPUT_ABSOLUTE_TOLERANCE,
    OUTPUT_ERROR,
    OUTPUT_RELATIVE_TOLERANCE,
    ROW_SUM_TOLERANCE,
    _as_integer,
)


def _decode(values: Sequence[int | float] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[int], list[float], list[float], list[float]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    for value in values:
        if type(value) not in (int, float) or not math_is_finite(value):
            return None
    states, symbols, length = (_as_integer(values[index]) for index in range(3))
    if (states is None or symbols is None or length is None
            or not 2 <= states <= MAX_STATES or not 2 <= symbols <= MAX_SYMBOLS
            or not 1 <= length <= MAX_SEQUENCE_LENGTH):
        return None
    if len(values) != 3 + states + states * states + states * symbols + length:
        return None
    cursor = 3
    initial = [float(value) for value in values[cursor:cursor + states]]
    cursor += states
    transition = [float(value) for value in values[cursor:cursor + states * states]]
    cursor += states * states
    emission = [float(value) for value in values[cursor:cursor + states * symbols]]
    cursor += states * symbols
    observations: list[int] = []
    for value in values[cursor:]:
        observation = _as_integer(value)
        if observation is None or not 0 <= observation < symbols:
            return None
        observations.append(observation)

    def valid(row: Sequence[float]) -> bool:
        return (all(MIN_PROBABILITY <= item <= 1.0 for item in row)
                and abs(sum(row) - 1.0) <= ROW_SUM_TOLERANCE)

    if not valid(initial):
        return None
    for state in range(states):
        if not valid(transition[state * states:(state + 1) * states]):
            return None
        if not valid(emission[state * symbols:(state + 1) * symbols]):
            return None
    return states, symbols, observations, initial, transition, emission


def math_is_finite(value: int | float) -> bool:
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _enumerate_paths(states: int, symbols: int, observations: Sequence[int],
                     initial: Sequence[float], transition: Sequence[float],
                     emission: Sequence[float]) -> list[float]:
    length = len(observations)
    likelihood = 0.0
    initial_counts = [0.0] * states
    transition_counts = [0.0] * (states * states)
    transition_occupancy = [0.0] * states
    emission_counts = [0.0] * (states * symbols)
    state_occupancy = [0.0] * states
    for path in itertools.product(range(states), repeat=length):
        weight = initial[path[0]] * emission[path[0] * symbols + observations[0]]
        for time in range(1, length):
            previous, current = path[time - 1], path[time]
            weight *= transition[previous * states + current]
            weight *= emission[current * symbols + observations[time]]
        likelihood += weight
        initial_counts[path[0]] += weight
        for time, state in enumerate(path):
            state_occupancy[state] += weight
            emission_counts[state * symbols + observations[time]] += weight
            if time + 1 < length:
                next_state = path[time + 1]
                transition_occupancy[state] += weight
                transition_counts[state * states + next_state] += weight

    new_initial = [count / likelihood for count in initial_counts]
    new_transition = list(transition)
    if length > 1:
        for source in range(states):
            for destination in range(states):
                new_transition[source * states + destination] = (
                    transition_counts[source * states + destination]
                    / transition_occupancy[source])
    new_emission = [0.0] * (states * symbols)
    for state in range(states):
        for symbol in range(symbols):
            new_emission[state * symbols + symbol] = (
                emission_counts[state * symbols + symbol] / state_occupancy[state])
    return [*new_initial, *new_transition, *new_emission]


def expected_output(values: Sequence[int | float] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, list[float]]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, []
    states, symbols, observations, initial, transition, emission = parsed
    result = _enumerate_paths(states, symbols, observations, initial, transition, emission)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < len(result)))):
        return OUTPUT_ERROR, []
    return len(result), result
