"""Kuhn matching plus alternating reachability and canonical-cover refinement."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_SIDE = 8
MAX_VERTICES = 2 * MAX_SIDE
MAX_VALID_INPUT_LENGTH = MAX_SIDE + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_WORKSPACE_BYTES = 8192
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, tuple[int, ...]] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    left_count, right_count = values[0], values[1]
    if not 0 <= left_count <= MAX_SIDE or not 0 <= right_count <= MAX_SIDE:
        return None
    if len(values) != left_count + 2:
        return None
    right_domain = (1 << right_count) - 1
    rows = tuple(values[2:])
    if any(row < 0 or row & ~right_domain for row in rows):
        return None
    return left_count, right_count, rows


def _maximum_matching(rows: tuple[int, ...], left_count: int,
                      right_count: int) -> tuple[list[int], int]:
    """Return right-to-left matches using ordered DFS augmenting paths."""
    match_right = [-1] * right_count

    def find(right: int, seen_right: list[bool]) -> bool:
        if seen_right[right]:
            return False
        seen_right[right] = True
        owner = match_right[right]
        if owner == -1:
            return True
        for candidate in range(right_count):
            if (rows[owner] & (1 << candidate)
                    and not seen_right[candidate]
                    and find(candidate, seen_right)):
                match_right[candidate] = owner
                return True
        return False

    size = 0
    for left in range(left_count):
        seen_right = [False] * right_count
        for right in range(right_count):
            if rows[left] & (1 << right) and find(right, seen_right):
                match_right[right] = left
                size += 1
                break
    return match_right, size


def _alternating_cover(rows: tuple[int, ...], left_count: int,
                       right_count: int, match_right: list[int]) -> int:
    """Construct KACTL's cover from unmatched-left alternating reachability."""
    matched_left = [False] * left_count
    for left in match_right:
        if left != -1:
            matched_left[left] = True

    reachable_left = [False] * left_count
    reachable_right = [False] * right_count
    queue: deque[int] = deque()
    for left in range(left_count):
        if not matched_left[left]:
            reachable_left[left] = True
            queue.append(left)

    while queue:
        left = queue.popleft()
        for right in range(right_count):
            if (rows[left] & (1 << right) and not reachable_right[right]
                    and match_right[right] != -1):
                reachable_right[right] = True
                owner = match_right[right]
                if not reachable_left[owner]:
                    reachable_left[owner] = True
                    queue.append(owner)

    cover_mask = 0
    for left in range(left_count):
        if not reachable_left[left]:
            cover_mask |= 1 << left
    for right in range(right_count):
        if reachable_right[right]:
            cover_mask |= 1 << (left_count + right)
    return cover_mask


def _minimum_completion_size(rows: tuple[int, ...], left_count: int,
                             right_count: int, states: list[int]) -> int | None:
    """Minimum cover size subject to states (-1 undecided, 0 out, 1 in)."""
    forced = states[:]
    changed = True
    while changed:
        changed = False
        for left in range(left_count):
            for right in range(right_count):
                if not rows[left] & (1 << right):
                    continue
                right_vertex = left_count + right
                if forced[left] == 0 and forced[right_vertex] == 0:
                    return None
                if forced[left] == 0 and forced[right_vertex] == -1:
                    forced[right_vertex] = 1
                    changed = True
                elif forced[right_vertex] == 0 and forced[left] == -1:
                    forced[left] = 1
                    changed = True

    forced_in = sum(state == 1 for state in forced)
    remaining_left = [left for left in range(left_count) if forced[left] == -1]
    remaining_right = [right for right in range(right_count)
                       if forced[left_count + right] == -1]
    match_slot = [-1] * len(remaining_right)

    def augment(left: int, seen: list[bool]) -> bool:
        for slot, right in enumerate(remaining_right):
            if not rows[left] & (1 << right) or seen[slot]:
                continue
            seen[slot] = True
            if match_slot[slot] == -1 or augment(match_slot[slot], seen):
                match_slot[slot] = left
                return True
        return False

    matching_size = 0
    for left in remaining_left:
        if augment(left, [False] * len(remaining_right)):
            matching_size += 1
    return forced_in + matching_size


def _solve(rows: tuple[int, ...], left_count: int, right_count: int) -> int:
    match_right, matching_size = _maximum_matching(rows, left_count, right_count)
    seed_cover = _alternating_cover(rows, left_count, right_count, match_right)
    optimum = seed_cover.bit_count()
    if optimum != matching_size:
        return INVALID_RESULT

    # Prefer exclusion at each vertex in the documented left-then-right order.
    # Repeated matching feasibility tests choose the unique lexicographically
    # smallest membership vector among all minimum covers.
    states = [-1] * (left_count + right_count)
    for vertex in range(len(states)):
        trial = states[:]
        trial[vertex] = 0
        if _minimum_completion_size(rows, left_count, right_count, trial) == optimum:
            states = trial
        else:
            states[vertex] = 1

    result = 0
    for vertex, state in enumerate(states):
        if state == 1:
            result |= 1 << vertex
    return result


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    left_count, right_count, rows = parsed
    return _solve(rows, left_count, right_count)
