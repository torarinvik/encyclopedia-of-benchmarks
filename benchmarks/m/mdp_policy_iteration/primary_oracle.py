"""Exact cycle-evaluation oracle for deterministic discounted MDP policy iteration."""
from __future__ import annotations

from fractions import Fraction
from math import gcd
from struct import pack

MAX_STATES = 4
MAX_ACTIONS = 3
MAX_INPUT_LENGTH = 28
MAX_OUTPUT_BYTES = 104


def _parse(values, *, input_is_null: bool = False, input_length: int | None = None):
    if values is None or input_is_null or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if input_length is not None and input_length != len(values):
        return None
    states, actions, p, q = values[:4]
    if not (1 <= states <= MAX_STATES and 1 <= actions <= MAX_ACTIONS
            and 0 <= p < q <= 4):
        return None
    if len(values) != 4 + 2 * states * actions:
        return None
    records = []
    for i in range(states * actions):
        reward, successor = values[4 + 2 * i:6 + 2 * i]
        if not -20 <= reward <= 20 or not 0 <= successor < states:
            return None
        records.append((reward, successor))
    return states, actions, p, q, records


def _evaluate_policy(states: int, actions: int, p: int, q: int,
                     records: list[tuple[int, int]], policy: list[int]) -> list[Fraction]:
    values: list[Fraction | None] = [None] * states
    discount = Fraction(p, q)
    for start in range(states):
        path: list[int] = []
        first_seen = [-1] * states
        current = start
        while first_seen[current] < 0:
            first_seen[current] = len(path)
            path.append(current)
            current = records[path[-1] * actions + policy[path[-1]]][1]
        cycle_start = first_seen[current]
        cycle_length = len(path) - cycle_start
        cycle_numerator = sum(
            records[path[cycle_start + j] * actions + policy[path[cycle_start + j]]][0]
            * (p ** j) * (q ** (cycle_length - j))
            for j in range(cycle_length)
        )
        cycle_denominator = q ** cycle_length - p ** cycle_length
        common = gcd(abs(cycle_numerator), cycle_denominator)
        values[path[cycle_start]] = Fraction(cycle_numerator // common, cycle_denominator // common)

        for j in range(len(path) - 1, cycle_start, -1):
            state = path[j]
            successor = path[j + 1] if j + 1 < len(path) else path[cycle_start]
            reward = records[state * actions + policy[state]][0]
            values[state] = Fraction(reward) + discount * values[successor]
        for j in range(cycle_start - 1, -1, -1):
            state = path[j]
            successor = path[j + 1]
            reward = records[state * actions + policy[state]][0]
            values[state] = Fraction(reward) + discount * values[successor]

    return [value for value in values if value is not None]


def _greedy_policy(states: int, actions: int, p: int, q: int,
                   records: list[tuple[int, int]], values: list[Fraction]) -> list[int]:
    result = []
    for state in range(states):
        best_action = 0
        best_value = Fraction(records[state * actions][0]) + Fraction(p, q) * values[records[state * actions][1]]
        for action in range(1, actions):
            reward, successor = records[state * actions + action]
            candidate = Fraction(reward) + Fraction(p, q) * values[successor]
            if candidate > best_value:
                best_action, best_value = action, candidate
        result.append(best_action)
    return result


def solve(values, *, input_is_null: bool = False,
          input_length: int | None = None) -> tuple[list[int], list[Fraction]] | None:
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return None
    states, actions, p, q, records = parsed
    policy = [0] * states
    for _ in range(actions ** states):
        state_values = _evaluate_policy(states, actions, p, q, records, policy)
        improved = _greedy_policy(states, actions, p, q, records, state_values)
        if improved == policy:
            return policy, state_values
        policy = improved
    return None


def expected_output(values, *, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return -1, b""
    result = solve(values, input_length=input_length)
    if result is None:
        return -1, b""
    policy, state_values = result
    output_bytes = (1 + 3 * len(policy)) * 8
    if output_is_null or (capacity is not None and capacity < output_bytes):
        return -2, b""
    words = [len(policy), *policy]
    for value in state_values:
        words.extend((value.numerator, value.denominator))
    return output_bytes, b"".join(pack("<q", word) for word in words)
