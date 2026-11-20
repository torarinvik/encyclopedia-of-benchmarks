"""Stable k-way Huffman merge reference for full nonbinary trees."""

from __future__ import annotations

from collections.abc import Sequence

MIN_ARITY = 3
MAX_ARITY = 4
MAX_SYMBOLS = 10
MAX_WEIGHT = 1000
MAX_VALID_INPUT_LENGTH = 12
MAX_PARSEABLE_INPUT_LENGTH = 13
MAX_RESULT = 90000
WORKSPACE_BYTES = 1024
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


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

    active = [(weight, symbol_id) for symbol_id, weight in enumerate(weights)]
    next_id = len(active)
    cost = 0
    while len(active) > 1:
        chosen: list[tuple[int, int]] = []
        for _ in range(arity):
            best_index = min(range(len(active)), key=lambda i: active[i])
            chosen.append(active.pop(best_index))
        combined = sum(weight for weight, _ in chosen)
        cost += combined
        active.append((combined, next_id))
        next_id += 1
    return cost
