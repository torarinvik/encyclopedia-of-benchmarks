"""Primary fixed-point integer oracle for bounded deterministic value iteration."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 29
MAX_OUTPUT_BYTES = 72


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 7 <= len(values) <= MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    states, actions, horizon, p, q = values[:5]
    if not 1 <= states <= 4 or not 1 <= actions <= 3 or not 1 <= horizon <= 8:
        return None
    if q < 1 or q > 4 or p < 0 or p >= q or len(values) != 5 + 2 * states * actions:
        return None
    rewards, targets = [], []
    offset = 5
    for _state in range(states):
        state_rewards, state_targets = [], []
        for _action in range(actions):
            reward, target = values[offset], values[offset + 1]
            offset += 2
            if not -100 <= reward <= 100 or not 0 <= target < states:
                return None
            state_rewards.append(reward)
            state_targets.append(target)
        rewards.append(state_rewards)
        targets.append(state_targets)
    return states, actions, horizon, p, q, rewards, targets


def _solve(parsed):
    states, actions, horizon, p, q, rewards, targets = parsed
    scale = q ** horizon
    value = [0] * states
    policy = [0] * states
    for _ in range(horizon):
        next_value = [0] * states
        for state in range(states):
            best = None
            best_action = 0
            for action in range(actions):
                candidate = rewards[state][action] * scale + p * (value[targets[state][action]] // q)
                if best is None or candidate > best:
                    best, best_action = candidate, action
            next_value[state] = best
            policy[state] = best_action
        value = next_value
    return [scale, *value, *policy]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    fields = _solve(parsed)
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
