"""Irving two-phase list-reduction reference for the bounded workload."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_PARTICIPANTS = 2
MAX_PARTICIPANTS = 8
MAX_VALID_INPUT_LENGTH = 57
MAX_PARSEABLE_INPUT_LENGTH = 58
WORKSPACE_BYTES = 32_768


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values:
        return None
    n = values[0]
    if (type(n) is not int or n < MIN_PARTICIPANTS or n > MAX_PARTICIPANTS
            or n % 2 or len(values) != 1 + n * (n - 1)):
        return None

    preferences: list[list[int]] = []
    cursor = 1
    for person in range(n):
        row = values[cursor:cursor + n - 1]
        cursor += n - 1
        if (any(type(other) is not int or not 0 <= other < n or other == person
                for other in row)
                or len(set(row)) != n - 1):
            return None
        # A self sentinel occupies the final slot, as in Irving's array form.
        preferences.append([*row, person])
    return n, preferences


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, preference = decoded

    rank = [[n - 1] * n for _ in range(n)]
    for person in range(n):
        for position, other in enumerate(preference[person]):
            rank[person][other] = position

    left = [0] * n
    right = [n - 1] * n

    # Phase 1: proposals remove partners ruled out by a rejection.
    proposed_to = [False] * n
    proposer = choice = 0
    for person in range(n):
        proposer = person
        while True:
            choice = preference[proposer][left[proposer]]
            if choice == proposer:
                return 0
            current = preference[choice][right[choice]]
            while rank[choice][proposer] > rank[choice][current]:
                left[proposer] += 1
                if left[proposer] >= n:
                    return 0
                choice = preference[proposer][left[proposer]]
                if choice == proposer:
                    return 0
                current = preference[choice][right[choice]]
            right[choice] = rank[choice][proposer]
            proposer = current
            if not proposed_to[choice]:
                break
        proposed_to[choice] = True

    possible = proposer == choice and all(left[p] <= right[p] for p in range(n))
    if not possible:
        return 0

    # Phase 2 follows the paper's cached-tail cycle search. `second[p]` is
    # the original row position of p's second surviving choice.
    second = [left[p] + 1 for p in range(n)]
    first_unmatched = 0
    first_in_cycle = 0
    tail: set[int] = set()
    cycle = [0] * (2 * n + 2)

    while True:
        while first_unmatched < n and left[first_unmatched] == right[first_unmatched]:
            first_unmatched += 1
        if first_unmatched == n:
            return 1 if _singleton_lists_are_reciprocal(preference, left, right, n) else 0

        if first_in_cycle > 0:
            person = cycle[first_in_cycle - 1]
            position = first_in_cycle - 1
            cycle_set = set(tail)
        else:
            person = first_unmatched
            position = 0
            cycle_set: set[int] = set()

        while True:
            cycle_set.add(person)
            if position >= len(cycle):
                return 0
            cycle[position] = person
            position += 1

            list_position = second[person]
            while list_position < n:
                next_choice = preference[person][list_position]
                list_position += 1
                if next_choice == person:
                    return 0
                if rank[next_choice][person] <= right[next_choice]:
                    break
            else:
                return 0
            second[person] = list_position - 1
            person = preference[next_choice][right[next_choice]]
            if person in cycle_set:
                break

        last_in_cycle = position - 1
        tail = set(cycle_set)
        position -= 1
        while position >= 0:
            tail.discard(cycle[position])
            if cycle[position] == person:
                break
            position -= 1
        if position < 0:
            return 0
        first_in_cycle = position

        # Phase-2 reduction: each cycle member moves to its second choice,
        # which cuts that choice's list at the corresponding proposer.
        for cycle_position in range(first_in_cycle, last_in_cycle + 1):
            proposer = cycle[cycle_position]
            left[proposer] = second[proposer]
            second[proposer] = left[proposer] + 1
            next_choice = preference[proposer][left[proposer]]
            right[next_choice] = rank[next_choice][proposer]
        if any(left[cycle[position]] > right[cycle[position]]
               for position in range(first_in_cycle, last_in_cycle + 1)):
            return 0


def _singleton_lists_are_reciprocal(preference, left, right, n: int) -> bool:
    for person in range(n):
        if left[person] != right[person]:
            return False
        partner = preference[person][left[person]]
        if partner == person or preference[partner][left[partner]] != person:
            return False
    return True
