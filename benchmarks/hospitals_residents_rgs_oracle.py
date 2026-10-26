"""Resident-oriented deferred-acceptance oracle for Hospitals/Residents."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_R = 8
MAX_H = 8
MAX_INPUT = 154
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * MAX_R


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 5 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    residents, hospitals = values[0], values[1]
    if not 1 <= residents <= MAX_R or not 1 <= hospitals <= MAX_H:
        return None
    expected = 2 + hospitals + residents + residents * hospitals + hospitals + hospitals * residents
    if len(values) != expected:
        return None
    cursor = 2
    capacities = list(values[cursor:cursor + hospitals])
    cursor += hospitals
    if any(not 1 <= capacity <= residents for capacity in capacities):
        return None
    resident_lengths = list(values[cursor:cursor + residents])
    cursor += residents
    resident_preferences: list[list[int]] = []
    resident_accepts = [[False] * hospitals for _ in range(residents)]
    for resident, count in enumerate(resident_lengths):
        if not 0 <= count <= hospitals:
            return None
        row = list(values[cursor:cursor + hospitals])
        cursor += hospitals
        prefix = row[:count]
        if (any(not 0 <= hospital < hospitals for hospital in prefix)
                or len(set(prefix)) != count or any(value != -1 for value in row[count:])):
            return None
        resident_preferences.append(prefix)
        for hospital in prefix:
            resident_accepts[resident][hospital] = True
    hospital_lengths = list(values[cursor:cursor + hospitals])
    cursor += hospitals
    hospital_rank = [[-1] * residents for _ in range(hospitals)]
    for hospital, count in enumerate(hospital_lengths):
        if not 0 <= count <= residents:
            return None
        row = list(values[cursor:cursor + residents])
        cursor += residents
        prefix = row[:count]
        if (any(not 0 <= resident < residents for resident in prefix)
                or len(set(prefix)) != count or any(value != -1 for value in row[count:])):
            return None
        for position, resident in enumerate(prefix):
            hospital_rank[hospital][resident] = position
    if any(resident_accepts[r][h] != (hospital_rank[h][r] >= 0)
           for r in range(residents) for h in range(hospitals)):
        return None
    return residents, hospitals, capacities, resident_preferences, hospital_rank


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    residents, hospitals, capacities, preferences, rank = parsed
    if output_is_null or capacity is not None and capacity < 8 * residents:
        return -2, b""

    assignment = [-1] * residents
    next_choice = [0] * residents
    occupancy = [0] * hospitals
    while True:
        proposer = next((r for r in range(residents)
                         if assignment[r] == -1 and next_choice[r] < len(preferences[r])), None)
        if proposer is None:
            break
        hospital = preferences[proposer][next_choice[proposer]]
        next_choice[proposer] += 1
        if occupancy[hospital] < capacities[hospital]:
            assignment[proposer] = hospital
            occupancy[hospital] += 1
            continue
        worst = max((r for r in range(residents) if assignment[r] == hospital),
                    key=lambda r: rank[hospital][r])
        if rank[hospital][proposer] < rank[hospital][worst]:
            assignment[worst] = -1
            assignment[proposer] = hospital
    output = b"".join(struct.pack("<q", hospital) for hospital in assignment)
    return len(output), output
