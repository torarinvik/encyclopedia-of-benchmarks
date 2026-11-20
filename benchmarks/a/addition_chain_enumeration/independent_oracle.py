"""Level-frontier exhaustive verifier for shortest addition chains."""
from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import MAX_OUTPUT_BYTES, MAX_TARGET, _parse


def _is_brauer(chain: tuple[int, ...]) -> bool:
    return all(any(chain[index - 1] + earlier == chain[index]
                   for earlier in chain[:index])
               for index in range(1, len(chain)))


def _frontier_counts(target: int) -> tuple[int, int, int]:
    if target == 1:
        return 0, 1, 0
    upper = target.bit_length() - 1 + target.bit_count() - 1
    frontier = {(1,)}
    for depth in range(1, upper + 1):
        following: set[tuple[int, ...]] = set()
        solutions: set[tuple[int, ...]] = set()
        remaining_before_step = upper - depth + 1
        for chain in frontier:
            last = chain[-1]
            if last * (1 << remaining_before_step) < target:
                continue
            candidates = {chain[left] + chain[right]
                          for left in range(len(chain))
                          for right in range(left, len(chain))}
            for candidate in candidates:
                if candidate <= last or candidate > target:
                    continue
                child = chain + (candidate,)
                if candidate == target:
                    solutions.add(child)
                else:
                    following.add(child)
        if solutions:
            brauer = sum(_is_brauer(chain) for chain in solutions)
            return depth, brauer, len(solutions) - brauer
        frontier = following
    raise ValueError("positive target was not reached")


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    target = _parse(values, input_is_null, input_length)
    if target is None:
        return result == -1 and output == b""
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int or capacity < 0
            or output_is_null or capacity < MAX_OUTPUT_BYTES):
        return result == -2 and output == b""
    try:
        expected = _frontier_counts(target)
    except ValueError:
        return False
    if not isinstance(output, (bytes, bytearray)) or result != MAX_OUTPUT_BYTES or len(output) != MAX_OUTPUT_BYTES:
        return False
    try:
        return struct.unpack("<qqq", output) == expected
    except struct.error:
        return False
