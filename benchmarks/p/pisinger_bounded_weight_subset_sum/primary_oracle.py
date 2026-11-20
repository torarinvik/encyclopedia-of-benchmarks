"""Pisinger's balanced state update for bounded-weight subset sum."""

from __future__ import annotations

MAX_ITEMS = 32
MAX_TARGET = 256
MAX_WEIGHT = 12
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
WORKSPACE_BYTES = 1024


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, target = values[:2]
    if not 0 <= n <= MAX_ITEMS or not 0 <= target <= MAX_TARGET:
        return None
    if len(values) != n + 2:
        return None
    weights = values[2:]
    if any(not 1 <= weight <= MAX_WEIGHT for weight in weights):
        return None
    return target, weights


def _balanced_subset_sum(target: int, weights: list[int]) -> int:
    """Run the 2W-state Pisinger recurrence with zero-based item boundaries."""
    count = len(weights)
    prefix_sum = 0
    break_index = 0
    while (break_index < count
           and prefix_sum + weights[break_index] <= target):
        prefix_sum += weights[break_index]
        break_index += 1
    if break_index == count:
        return prefix_sum

    width = max(weights)
    previous = [-1] * (2 * width)
    previous[prefix_sum + width - target - 1] = break_index

    for item_index in range(break_index, count):
        weight = weights[item_index]
        current = previous.copy()

        # Insert the new item into every low-side state. Slot zero represents
        # target-width+1, so the shift is mass+width-target-1.
        for state_index in range(width):
            destination = state_index + weight
            if previous[state_index] > current[destination]:
                current[destination] = previous[state_index]

        # Repair over-target states, from high to low, by removing earlier
        # items in the interval [previous boundary, current boundary).
        for state_index in range(2 * width - 1, width - 1, -1):
            first_item = max(0, previous[state_index])
            stop_item = current[state_index]
            for removed_item in range(first_item, stop_item):
                reduced_state = state_index - weights[removed_item]
                if removed_item > current[reduced_state]:
                    current[reduced_state] = removed_item

        previous = current

    # The greedy break prefix is within W-1 of target, so a reachable state
    # occurs before the search could leave the allocated lower boundary.
    for mass in range(target, max(-1, target - width), -1):
        if previous[mass + width - target - 1] >= 0:
            return mass
    return 0


def expected_result(values, input_is_null=False, input_length=None):
    """Return the best bounded subset sum or -1 for malformed input."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return -1
    target, weights = parsed
    return _balanced_subset_sum(target, weights)
