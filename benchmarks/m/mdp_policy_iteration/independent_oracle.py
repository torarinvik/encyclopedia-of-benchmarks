"""Exhaustive policy verifier using exact rational Gaussian elimination."""
from __future__ import annotations

from fractions import Fraction
from itertools import product
from struct import unpack


def _parse(values, input_is_null: bool, input_length: int | None):
    if values is None or input_is_null or len(values) < 4 or len(values) > 28:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if input_length is not None and input_length != len(values):
        return None
    states, actions, p, q = values[:4]
    if not (1 <= states <= 4 and 1 <= actions <= 3 and 0 <= p < q <= 4):
        return None
    if len(values) != 4 + 2 * states * actions:
        return None
    records = []
    for at in range(4, len(values), 2):
        reward, successor = values[at:at + 2]
        if not -20 <= reward <= 20 or not 0 <= successor < states:
            return None
        records.append((reward, successor))
    return states, actions, Fraction(p, q), records


def _solve_linear(matrix: list[list[Fraction]], rhs: list[Fraction]) -> list[Fraction]:
    n = len(rhs)
    rows = [matrix[i][:] + [rhs[i]] for i in range(n)]
    for column in range(n):
        pivot = next((row for row in range(column, n) if rows[row][column]), None)
        if pivot is None:
            raise ValueError("singular policy evaluation system")
        rows[column], rows[pivot] = rows[pivot], rows[column]
        scale = rows[column][column]
        rows[column] = [value / scale for value in rows[column]]
        for row in range(n):
            if row == column:
                continue
            factor = rows[row][column]
            if factor:
                rows[row] = [x - factor * y for x, y in zip(rows[row], rows[column])]
    return [rows[i][-1] for i in range(n)]


def _evaluate(states: int, actions: int, discount: Fraction,
              records: list[tuple[int, int]], policy: tuple[int, ...]) -> list[Fraction]:
    matrix = [[Fraction(int(row == col)) for col in range(states)] for row in range(states)]
    rhs = []
    for state in range(states):
        reward, successor = records[state * actions + policy[state]]
        matrix[state][successor] -= discount
        rhs.append(Fraction(reward))
    return _solve_linear(matrix, rhs)


def _optimal_values(states: int, actions: int, discount: Fraction,
                    records: list[tuple[int, int]]) -> list[Fraction]:
    best: list[Fraction | None] = [None] * states
    for policy in product(range(actions), repeat=states):
        values = _evaluate(states, actions, discount, records, policy)
        for state, value in enumerate(values):
            if best[state] is None or value > best[state]:
                best[state] = value
    return [value for value in best if value is not None]


def verify_result(values, result: int, payload: bytes, *,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and payload == b""
    states, actions, discount, records = parsed
    output_bytes = (1 + 3 * states) * 8
    if output_is_null or (output_capacity is not None and output_capacity < output_bytes):
        return result == -2 and payload == b""
    if result != output_bytes or len(payload) != output_bytes:
        return False
    words = list(unpack("<" + "q" * (1 + 3 * states), payload))
    if words[0] != states:
        return False
    policy = words[1:1 + states]
    if any(not 0 <= action < actions for action in policy):
        return False
    reported = []
    for state in range(states):
        numerator, denominator = words[1 + states + 2 * state:1 + states + 2 * state + 2]
        if denominator <= 0:
            return False
        value = Fraction(numerator, denominator)
        if (value.numerator, value.denominator) != (numerator, denominator):
            return False
        reported.append(value)
    try:
        policy_values = _evaluate(states, actions, discount, records, tuple(policy))
        optimal = _optimal_values(states, actions, discount, records)
    except (ValueError, ZeroDivisionError):
        return False
    if policy_values != reported or reported != optimal:
        return False
    for state in range(states):
        q_values = [Fraction(records[state * actions + action][0])
                    + discount * reported[records[state * actions + action][1]]
                    for action in range(actions)]
        best_value = max(q_values)
        if reported[state] != best_value or policy[state] != q_values.index(best_value):
            return False
    return True
