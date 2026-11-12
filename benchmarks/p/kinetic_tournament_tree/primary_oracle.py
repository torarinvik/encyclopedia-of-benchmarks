"""Certificate-maintained segment tournament for translated linear functions."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 8
MAX_M = 32
BASE = 8
MAX_INPUT_LENGTH = 2 + 2 * MAX_N + 4 * MAX_M
MAX_OUTPUT_BYTES = 8 * MAX_M
MAX_WORKSPACE_BYTES = 8192
INF = (1 << 60)
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[list[int], list[int], list[tuple[int, ...]]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    cursor = 2
    if cursor + 2 * n > len(values):
        return None
    slopes: list[int] = []
    intercepts: list[int] = []
    for _ in range(n):
        slope, intercept = values[cursor], values[cursor + 1]
        cursor += 2
        if not -8 <= slope <= 8 or not -64 <= intercept <= 64:
            return None
        if slopes and slope <= slopes[-1]:
            return None
        slopes.append(slope)
        intercepts.append(intercept)

    operations: list[tuple[int, ...]] = []
    query_count = 0
    for _ in range(m):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        if kind == 0:
            if cursor + 4 > len(values):
                return None
            left, right, delta = values[cursor + 1:cursor + 4]
            if not 0 <= left <= right < n or not 1 <= delta <= 8:
                return None
            operations.append((0, left, right, delta))
            cursor += 4
        elif kind == 1:
            if cursor + 3 > len(values):
                return None
            left, right = values[cursor + 1:cursor + 3]
            if not 0 <= left <= right < n:
                return None
            operations.append((1, left, right))
            query_count += 1
            cursor += 3
        else:
            return None
    if cursor != len(values) or query_count == 0:
        return None
    return slopes, intercepts, operations


def _cross_deadline(
    winner: int,
    loser: int,
    winner_value: int,
    loser_value: int,
    slopes: list[int],
) -> int:
    if slopes[winner] >= slopes[loser]:
        return INF
    gap = winner_value - loser_value
    if gap <= 0:
        return 0
    slope_gap = slopes[loser] - slopes[winner]
    return (gap + slope_gap - 1) // slope_gap


def _run_ktt(
    slopes: list[int],
    intercepts: list[int],
    operations: list[tuple[int, ...]],
) -> list[int]:
    size = 2 * BASE
    valid = [False] * size
    winner = [0] * size
    best = [0] * size
    lazy = [0] * size
    deadline = [INF] * size

    for index in range(len(slopes)):
        node = BASE + index
        valid[node] = True
        winner[node] = index
        best[node] = intercepts[index]

    def pull(node: int) -> None:
        left, right = 2 * node, 2 * node + 1
        if not valid[left] and not valid[right]:
            valid[node] = False
            deadline[node] = INF
            return
        if not valid[left] or not valid[right]:
            child = right if valid[right] else left
            valid[node] = True
            winner[node] = winner[child]
            best[node] = best[child]
            deadline[node] = deadline[child]
            return
        li, ri = winner[left], winner[right]
        if best[left] > best[right] or (
            best[left] == best[right] and slopes[li] > slopes[ri]
        ):
            winning_child, losing_child = left, right
        else:
            winning_child, losing_child = right, left
        wi, lo = winner[winning_child], winner[losing_child]
        valid[node] = True
        winner[node] = wi
        best[node] = best[winning_child]
        cross = _cross_deadline(wi, lo, best[winning_child], best[losing_child], slopes)
        deadline[node] = min(cross, deadline[left], deadline[right])

    for node in range(BASE - 1, 0, -1):
        pull(node)

    def apply(node: int, delta: int) -> None:
        if not valid[node]:
            return
        best[node] += slopes[winner[node]] * delta
        lazy[node] += delta
        deadline[node] -= delta

    def push(node: int) -> None:
        delta = lazy[node]
        if delta == 0 or node >= BASE:
            return
        apply(2 * node, delta)
        apply(2 * node + 1, delta)
        lazy[node] = 0

    def repair(node: int) -> None:
        if node >= BASE or not valid[node]:
            return
        push(node)
        if valid[2 * node] and deadline[2 * node] <= 0:
            repair(2 * node)
        if valid[2 * node + 1] and deadline[2 * node + 1] <= 0:
            repair(2 * node + 1)
        pull(node)

    def translate(node: int, lo: int, hi: int, ql: int, qr: int, delta: int) -> None:
        if ql <= lo and hi <= qr:
            apply(node, delta)
            repair(node)
            return
        push(node)
        mid = (lo + hi) // 2
        if ql < mid:
            translate(2 * node, lo, mid, ql, qr, delta)
        if mid < qr:
            translate(2 * node + 1, mid, hi, ql, qr, delta)
        pull(node)

    def query(node: int, lo: int, hi: int, ql: int, qr: int) -> int:
        if ql <= lo and hi <= qr:
            return best[node]
        push(node)
        mid = (lo + hi) // 2
        result: int | None = None
        if ql < mid:
            result = query(2 * node, lo, mid, ql, qr)
        if mid < qr:
            right_result = query(2 * node + 1, mid, hi, ql, qr)
            result = right_result if result is None else max(result, right_result)
        pull(node)
        return result if result is not None else 0

    answers: list[int] = []
    for operation in operations:
        if operation[0] == 0:
            _, left, right, delta = operation
            translate(1, 0, BASE, left, right + 1, delta)
        else:
            _, left, right = operation
            answers.append(query(1, 0, BASE, left, right + 1))
    return answers


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    slopes, intercepts, operations = parsed
    query_count = sum(operation[0] == 1 for operation in operations)
    byte_count = 8 * query_count
    if output_is_null or (output_capacity is not None and output_capacity < byte_count):
        return OUTPUT_ERROR, b""
    answers = _run_ktt(slopes, intercepts, operations)
    return byte_count, b"".join(struct.pack("<q", answer) for answer in answers)
