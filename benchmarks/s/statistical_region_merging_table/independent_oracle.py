"""Flat region-label and exact-rational reference for supplied-bound merging."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT_LENGTH = 74
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _valid_input(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX
                   for item in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    rows, columns = values[:2]
    if rows not in range(1, 7) or columns not in range(1, 7):
        return None
    total = rows * columns
    if len(values) != 2 + total * 2:
        return None
    limits = values[2:2 + total]
    shades = values[2 + total:]
    if any(item < 0 or item > 65535 for item in limits):
        return None
    if any(item < 0 or item > 255 for item in shades):
        return None
    return rows, columns, tuple(limits), tuple(shades)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Simulate ordered merges by relabeling members and comparing exact means."""
    if (type(output_is_null) is not bool
            or capacity is not None
            and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    decoded = _valid_input(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    rows, columns, limits, intensities = decoded
    pixel_count = rows * columns
    labels = list(range(pixel_count))

    for target_difference in range(256):
        for position in range(pixel_count):
            candidate_neighbors = []
            if position % columns != columns - 1:
                candidate_neighbors.append(position + 1)
            if position + columns < pixel_count:
                candidate_neighbors.append(position + columns)
            for neighbor in candidate_neighbors:
                if abs(intensities[position] - intensities[neighbor]) != target_difference:
                    continue
                first_label, second_label = labels[position], labels[neighbor]
                if first_label == second_label:
                    continue
                first_members = [i for i, label in enumerate(labels)
                                 if label == first_label]
                second_members = [i for i, label in enumerate(labels)
                                  if label == second_label]
                first_count, second_count = len(first_members), len(second_members)
                first_mean = Fraction(
                    sum(intensities[i] for i in first_members), first_count
                )
                second_mean = Fraction(
                    sum(intensities[i] for i in second_members), second_count
                )
                if ((first_mean - second_mean) ** 2
                        > limits[first_count - 1] + limits[second_count - 1]):
                    continue
                new_label = min(first_members + second_members)
                for member in first_members:
                    labels[member] = new_label
                for member in second_members:
                    labels[member] = new_label

    if output_is_null or capacity is not None and capacity < pixel_count:
        return -2, b""
    return pixel_count, bytes(labels)
