"""Independent exact verifier using a capacity-state DP for fixed policies."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction
from functools import cmp_to_key

MAX_INPUT_LENGTH = 43
MAX_OUTPUT_BYTES = 72


def _decode(data):
    if not isinstance(data, (list, tuple)) or not 2 <= len(data) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in data):
        return None
    count, bound = data[0], data[1]
    if not 1 <= count <= 5 or not 1 <= bound <= 8:
        return None
    cursor = 2
    rewards, laws, denominators, fits, means = [], [], [], [], []
    for _item in range(count):
        if cursor + 2 > len(data):
            return None
        reward, alternatives = data[cursor], data[cursor + 1]
        cursor += 2
        if not 0 <= reward <= 20 or not 1 <= alternatives <= 3:
            return None
        outcomes = []
        total_probability = 0
        fitting_probability = 0
        capped_size_sum = 0
        for _ in range(alternatives):
            if cursor + 2 > len(data):
                return None
            size, probability = data[cursor], data[cursor + 1]
            cursor += 2
            if not 0 <= size <= bound + 1 or not 1 <= probability <= 3:
                return None
            outcomes.append((size, probability))
            total_probability += probability
            fitting_probability += probability if size <= bound else 0
            capped_size_sum += min(size, bound) * probability
        if total_probability > 9 or capped_size_sum == 0:
            return None
        rewards.append(reward)
        laws.append(outcomes)
        denominators.append(total_probability)
        fits.append(fitting_probability)
        means.append(capped_size_sum)
    if cursor != len(data):
        return None
    return bound, rewards, laws, denominators, fits, means


def _policy_numerator(bound, rewards, laws, denominators, order):
    states = [0] * (bound + 1)
    states[0] = 1
    suffix_scale = 1
    for denominator in denominators:
        suffix_scale *= denominator
    numerator = 0
    for position, item in enumerate(order):
        suffix_scale //= denominators[item]
        following = [0] * (bound + 1)
        for used, mass in enumerate(states):
            if mass == 0:
                continue
            for size, probability in laws[item]:
                joint_mass = mass * probability
                if used + size <= bound:
                    following[used + size] += joint_mass
                    numerator += joint_mass * rewards[item] * suffix_scale
        states = following
    return numerator


def _payload(decoded):
    bound, rewards, laws, denominators, fits, means = decoded
    item_count = len(rewards)

    def density_compare(left, right):
        cross_left = rewards[left] * fits[left] * means[right]
        cross_right = rewards[right] * fits[right] * means[left]
        if cross_left != cross_right:
            return -1 if cross_left > cross_right else 1
        return (left > right) - (left < right)

    order = sorted(range(item_count), key=cmp_to_key(density_compare))
    best_single = min(range(item_count), key=lambda i: (
        -Fraction(rewards[i] * fits[i], denominators[i]), i))
    full_denominator = 1
    for q in denominators:
        full_denominator *= q
    single_numerator = rewards[best_single] * fits[best_single] * (full_denominator // denominators[best_single])
    ordered_numerator = _policy_numerator(bound, rewards, laws, denominators, order)
    if ordered_numerator > single_numerator:
        kind, selected, numerator = 1, order, ordered_numerator
    else:
        kind, selected, numerator = 0, [best_single], single_numerator
    words = [kind, len(selected), *selected, numerator, full_denominator]
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    payload = _payload(decoded)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
