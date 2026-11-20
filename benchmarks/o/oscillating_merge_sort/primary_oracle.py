"""Recursive oscillating-sort reference for the fixed sort_call profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 1024
INITIAL_RUN_SIZE = 16
MERGE_INPUTS = 2
TOTAL_TAPES = 4
MAX_WORKSPACE_BYTES = (6 * MERGE_INPUTS * MAX_LENGTH + MAX_LENGTH) * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        raise ValueError("oscillating merge sort accepts at most 1024 signed 64-bit values")
    run_count = (len(values) + INITIAL_RUN_SIZE - 1) // INITIAL_RUN_SIZE

    def build(first_run: int, count: int, ascending: bool) -> list[int]:
        if count == 1:
            start = first_run * INITIAL_RUN_SIZE
            run: list[int] = []
            for value in values[start:start + INITIAL_RUN_SIZE]:
                position = len(run)
                run.append(value)
                while position > 0 and (
                        value < run[position - 1] if ascending
                        else value > run[position - 1]):
                    run[position] = run[position - 1]
                    position -= 1
                run[position] = value
            return run
        quotient, remainder = divmod(count, MERGE_INPUTS)
        children: list[list[int]] = []
        next_run = first_run
        for lane in range(MERGE_INPUTS):
            child_count = quotient + (lane < remainder)
            if child_count:
                children.append(build(next_run, child_count, not ascending))
                next_run += child_count

        heads = [len(child) - 1 for child in children]
        merged: list[int] = []
        for _ in range(sum(map(len, children))):
            best_lane = -1
            best_value = 0
            for lane, child in enumerate(children):
                if heads[lane] < 0:
                    continue
                candidate = child[heads[lane]]
                if (best_lane < 0
                        or (candidate < best_value if ascending else candidate > best_value)):
                    best_lane = lane
                    best_value = candidate
            merged.append(best_value)
            heads[best_lane] -= 1
        return merged

    return [] if run_count == 0 else build(0, run_count, True)
