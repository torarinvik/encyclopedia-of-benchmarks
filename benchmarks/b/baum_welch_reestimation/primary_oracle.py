"""Forward–backward Baum–Welch reference for one discrete HMM sequence."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_STATES = 4
MAX_SYMBOLS = 4
MAX_SEQUENCE_LENGTH = 8
MAX_VALID_INPUT_LENGTH = 3 + MAX_STATES + MAX_STATES**2 + MAX_STATES * MAX_SYMBOLS + MAX_SEQUENCE_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_STATES + MAX_STATES**2 + MAX_STATES * MAX_SYMBOLS
MIN_PROBABILITY = 0.001
ROW_SUM_TOLERANCE = 1e-9
OUTPUT_ABSOLUTE_TOLERANCE = 1e-9
OUTPUT_RELATIVE_TOLERANCE = 1e-9
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _as_integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is float and math.isfinite(value) and value.is_integer():
        return int(value)
    return None


def _parse(values: Sequence[int | float] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int], list[float], list[float], list[float]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    numbers: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except OverflowError:
            return None
        if not math.isfinite(number):
            return None
        numbers.append(number)
    states = _as_integer(values[0])
    symbols = _as_integer(values[1])
    sequence_length = _as_integer(values[2])
    if (states is None or symbols is None or sequence_length is None
            or not 2 <= states <= MAX_STATES
            or not 2 <= symbols <= MAX_SYMBOLS
            or not 1 <= sequence_length <= MAX_SEQUENCE_LENGTH):
        return None
    expected_length = 3 + states + states * states + states * symbols + sequence_length
    if len(values) != expected_length:
        return None
    cursor = 3
    initial = numbers[cursor:cursor + states]
    cursor += states
    transition = numbers[cursor:cursor + states * states]
    cursor += states * states
    emission = numbers[cursor:cursor + states * symbols]
    cursor += states * symbols
    observations: list[int] = []
    for value in values[cursor:]:
        observation = _as_integer(value)
        if observation is None or not 0 <= observation < symbols:
            return None
        observations.append(observation)

    def valid_distribution(row: Sequence[float]) -> bool:
        return (all(MIN_PROBABILITY <= item <= 1.0 for item in row)
                and abs(math.fsum(row) - 1.0) <= ROW_SUM_TOLERANCE)

    if not valid_distribution(initial):
        return None
    for state in range(states):
        if not valid_distribution(transition[state * states:(state + 1) * states]):
            return None
        if not valid_distribution(emission[state * symbols:(state + 1) * symbols]):
            return None
    return states, symbols, observations, initial, transition, emission


def _forward_backward(states: int, symbols: int, observations: Sequence[int],
                      initial: Sequence[float], transition: Sequence[float],
                      emission: Sequence[float]) -> list[float]:
    length = len(observations)
    alpha = [[0.0] * states for _ in range(length)]
    beta = [[0.0] * states for _ in range(length)]
    for state in range(states):
        alpha[0][state] = initial[state] * emission[state * symbols + observations[0]]
    for time in range(1, length):
        for destination in range(states):
            incoming = math.fsum(alpha[time - 1][source] * transition[source * states + destination]
                                 for source in range(states))
            alpha[time][destination] = incoming * emission[destination * symbols + observations[time]]
    likelihood = math.fsum(alpha[length - 1])
    for state in range(states):
        beta[length - 1][state] = 1.0
    for time in range(length - 2, -1, -1):
        for source in range(states):
            beta[time][source] = math.fsum(
                transition[source * states + destination]
                * emission[destination * symbols + observations[time + 1]]
                * beta[time + 1][destination]
                for destination in range(states))

    gamma = [[alpha[time][state] * beta[time][state] / likelihood
              for state in range(states)] for time in range(length)]
    new_initial = gamma[0]
    new_transition = list(transition)
    if length > 1:
        for source in range(states):
            denominator = math.fsum(gamma[time][source] for time in range(length - 1))
            for destination in range(states):
                expected_transitions = math.fsum(
                    alpha[time][source]
                    * transition[source * states + destination]
                    * emission[destination * symbols + observations[time + 1]]
                    * beta[time + 1][destination] / likelihood
                    for time in range(length - 1))
                new_transition[source * states + destination] = expected_transitions / denominator

    new_emission = [0.0] * (states * symbols)
    for state in range(states):
        denominator = math.fsum(gamma[time][state] for time in range(length))
        for symbol in range(symbols):
            numerator = math.fsum(gamma[time][state] for time in range(length)
                                  if observations[time] == symbol)
            new_emission[state * symbols + symbol] = numerator / denominator
    return [*new_initial, *new_transition, *new_emission]


def expected_output(values: Sequence[int | float] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, list[float]]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, []
    states, symbols, observations, initial, transition, emission = parsed
    result = _forward_backward(states, symbols, observations, initial, transition, emission)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < len(result)))):
        return OUTPUT_ERROR, []
    return len(result), result
