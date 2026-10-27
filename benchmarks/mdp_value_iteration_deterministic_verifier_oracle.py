"""Independent Fraction-based verifier for bounded deterministic value iteration."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 29)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if (input_is_null or not isinstance(values, (tuple, list)) or not 7 <= len(values) <= 29
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    states, actions, horizon, p, q = values[:5]
    if (not 1 <= states <= 4 or not 1 <= actions <= 3 or not 1 <= horizon <= 8
            or not 1 <= q <= 4 or not 0 <= p < q or len(values) != 5 + 2 * states * actions):
        return -1, b""
    rewards = [[0] * actions for _ in range(states)]
    targets = [[0] * actions for _ in range(states)]
    offset = 5
    for state in range(states):
        for action in range(actions):
            reward, target = values[offset], values[offset + 1]
            offset += 2
            if not -100 <= reward <= 100 or not 0 <= target < states:
                return -1, b""
            rewards[state][action], targets[state][action] = reward, target
    discount = Fraction(p, q)
    value = [Fraction(0) for _ in range(states)]
    policy = [0] * states
    for _ in range(horizon):
        next_value = []
        for state in range(states):
            candidates = [Fraction(rewards[state][action]) + discount * value[targets[state][action]]
                          for action in range(actions)]
            best = max(candidates)
            policy[state] = candidates.index(best)
            next_value.append(best)
        value = next_value
    scale = q ** horizon
    scaled = [int(item * scale) for item in value]
    fields = [scale, *scaled, *policy]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
