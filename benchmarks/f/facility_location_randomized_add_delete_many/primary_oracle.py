"""Primary clean-room replay oracle for randomized add-one/delete-many FL."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_CLIENTS = 5
MAX_FACILITIES = 5
MAX_DRAWS = 8
MAX_POINTS = MAX_CLIENTS + MAX_FACILITIES
MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_CLIENTS + MAX_POINTS * MAX_POINTS + MAX_FACILITIES + MAX_DRAWS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * (2 * MAX_DRAWS + 3 + MAX_CLIENTS)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, int, int, int, list[int], list[int],
                                           list[int], list[int], list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return None
    if (len(values) < 12 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n, facilities, draws, raw_mask = values[:4]
    if not (1 <= n <= MAX_CLIENTS and 1 <= facilities <= MAX_FACILITIES
            and 1 <= draws <= MAX_DRAWS and 0 < raw_mask < (1 << facilities)):
        return None
    points = n + facilities
    expected = 4 + 2 * n + points * points + facilities + draws
    if len(values) != expected:
        return None
    at = 4
    assignment = list(values[at:at + n])
    at += n
    demand = list(values[at:at + n])
    at += n
    if any(not 0 <= x < facilities or not (raw_mask & (1 << x)) for x in assignment):
        return None
    if any(not 1 <= x <= 10 for x in demand):
        return None
    metric = list(values[at:at + points * points])
    at += points * points
    if any(not 0 <= x <= 1000 for x in metric):
        return None
    for i in range(points):
        if metric[i * points + i] != 0:
            return None
        for j in range(points):
            ij = metric[i * points + j]
            if i != j and ij == 0:
                return None
            if ij != metric[j * points + i]:
                return None
            for k in range(points):
                if ij > metric[i * points + k] + metric[k * points + j]:
                    return None
    fee = list(values[at:at + facilities])
    at += facilities
    if any(not 0 <= x <= 1000 for x in fee):
        return None
    tape = list(values[at:at + draws])
    if any(not 0 <= x < facilities for x in tape):
        return None
    return n, facilities, draws, raw_mask, assignment, demand, metric, fee, tape, values


def _state_cost(n: int, facilities: int, points: int, mask: int,
                assignment: list[int], demand: list[int], metric: list[int],
                fee: list[int]) -> int:
    total = sum(fee[s] for s in range(facilities) if mask & (1 << s))
    for client, center in enumerate(assignment):
        total += demand[client] * metric[client * points + n + center]
    return total


def expected_output(values: Sequence[int] | None, *, capacity: int | None = None,
                    input_length: int | None = None, input_is_null: bool = False,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    n, facilities, draws, mask, assignment, demand, metric, fee, tape, _ = decoded
    points = n + facilities
    current_cost = _state_cost(n, facilities, points, mask, assignment, demand, metric, fee)
    costs_after: list[int] = []
    accepted: list[int] = []
    accepted_count = 0
    for candidate in tape:
        did_accept = 0
        candidate_bit = 1 << candidate
        if not (mask & candidate_bit):
            closer = [metric[j * points + n + candidate]
                      < metric[j * points + n + assignment[j]] for j in range(n)]
            gain = sum(demand[j] * (metric[j * points + n + assignment[j]]
                                    - metric[j * points + n + candidate])
                       for j in range(n) if closer[j]) - fee[candidate]
            drop_mask = 0
            for center in range(facilities):
                if not (mask & (1 << center)):
                    continue
                center_gain = fee[center]
                for j in range(n):
                    if assignment[j] == center and not closer[j]:
                        center_gain += demand[j] * (
                            metric[j * points + n + center]
                            - metric[j * points + n + candidate])
                if center_gain > 0:
                    drop_mask |= 1 << center
                    gain += center_gain
            if gain > 0:
                mask = (mask | candidate_bit) & ~drop_mask
                assignment = [candidate if closer[j] or (drop_mask & (1 << assignment[j]))
                              else assignment[j] for j in range(n)]
                current_cost = _state_cost(n, facilities, points, mask, assignment,
                                           demand, metric, fee)
                did_accept = 1
                accepted_count += 1
        costs_after.append(current_cost)
        accepted.append(did_accept)
    words = costs_after + accepted + [current_cost, mask] + assignment + [accepted_count]
    if type(output_is_null) is not bool:
        return -1, b""
    needed = 8 * len(words)
    if output_is_null or (capacity is not None and (type(capacity) is not int or capacity < needed)):
        return -2, b""
    return needed, b"".join(struct.pack("<q", word) for word in words)
