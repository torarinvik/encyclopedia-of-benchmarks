"""Full-tree enumeration reference, independent of greedy merging."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, MAX_PARSEABLE_INPUT_LENGTH, MAX_SYMBOLS, MAX_WEIGHT,
    )
except ImportError:
    from primary_oracle import (
        I64_MAX, I64_MIN, MAX_PARSEABLE_INPUT_LENGTH, MAX_SYMBOLS, MAX_WEIGHT,
    )


def _compositions(total: int, parts: int, arity: int) -> list[tuple[int, ...]]:
    allowed = [value for value in range(1, total + 1)
               if (value - 1) % (arity - 1) == 0]
    results: list[tuple[int, ...]] = []

    def visit(remaining_parts: int, remaining_total: int, prefix: list[int]) -> None:
        if remaining_parts == 1:
            if remaining_total in allowed:
                results.append(tuple(prefix + [remaining_total]))
            return
        for value in allowed:
            if value + (remaining_parts - 1) > remaining_total:
                break
            visit(remaining_parts - 1, remaining_total - value, prefix + [value])

    visit(parts, total, [])
    return results


def _depth_shapes(leaves: int, arity: int) -> list[tuple[int, ...]]:
    if leaves == 1:
        return [(0,)]
    shapes: list[tuple[int, ...]] = []
    for child_sizes in _compositions(leaves, arity, arity):
        child_options = [_depth_shapes(size, arity) for size in child_sizes]
        for children in product(*child_options):
            shapes.append(tuple(depth + 1 for child in children for depth in child))
    return shapes


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    arity, count = values[0], values[1]
    if arity not in (3, 4) or not 1 <= count <= MAX_SYMBOLS:
        return None
    if len(values) != count + 2:
        return None
    if count > 1 and (count - 1) % (arity - 1) != 0:
        return None
    weights = list(values[2:])
    if any(weight < 0 or weight > MAX_WEIGHT for weight in weights):
        return None
    return arity, weights


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    arity, weights = parsed
    if len(weights) == 1:
        return 0
    ordered_weights = sorted(weights, reverse=True)
    best: int | None = None
    for shape in _depth_shapes(len(weights), arity):
        ordered_depths = sorted(shape)
        cost = sum(weight * depth
                   for weight, depth in zip(ordered_weights, ordered_depths))
        if best is None or cost < best:
            best = cost
    if best is None:
        raise AssertionError("full k-ary tree shape was not generated")
    return best
