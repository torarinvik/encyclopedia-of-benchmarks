"""Round-based proposal verifier for Hospitals/Residents RGS."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_R = 8
MAX_H = 8
MAX_INPUT = 154
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * MAX_R


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
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 5 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values)):
        return -1, b""
    residents, hospitals = values[0], values[1]
    if not 1 <= residents <= MAX_R or not 1 <= hospitals <= MAX_H:
        return -1, b""
    expected = 2 + hospitals + residents + residents * hospitals + hospitals + hospitals * residents
    if len(values) != expected:
        return -1, b""
    offset = 2
    capacity_by_hospital = values[offset:offset + hospitals]
    offset += hospitals
    if any(not 1 <= c <= residents for c in capacity_by_hospital):
        return -1, b""
    resident_counts = values[offset:offset + residents]
    offset += residents
    resident_lists: list[list[int]] = []
    mutually_acceptable: set[tuple[int, int]] = set()
    for resident, count in enumerate(resident_counts):
        if not 0 <= count <= hospitals:
            return -1, b""
        row = values[offset:offset + hospitals]
        offset += hospitals
        prefs = list(row[:count])
        if (any(not 0 <= hospital < hospitals for hospital in prefs)
                or len(set(prefs)) != count or any(x != -1 for x in row[count:])):
            return -1, b""
        resident_lists.append(prefs)
        mutually_acceptable.update((resident, hospital) for hospital in prefs)
    hospital_counts = values[offset:offset + hospitals]
    offset += hospitals
    hospital_lists: list[list[int]] = []
    for hospital, count in enumerate(hospital_counts):
        if not 0 <= count <= residents:
            return -1, b""
        row = values[offset:offset + residents]
        offset += residents
        prefs = list(row[:count])
        if (any(not 0 <= resident < residents for resident in prefs)
                or len(set(prefs)) != count or any(x != -1 for x in row[count:])):
            return -1, b""
        hospital_lists.append(prefs)
    hospital_accepts = {(resident, hospital) for hospital, prefs in enumerate(hospital_lists)
                        for resident in prefs}
    if mutually_acceptable != hospital_accepts:
        return -1, b""
    if output_is_null or capacity is not None and capacity < 8 * residents:
        return -2, b""

    hospital_rank = [{resident: rank for rank, resident in enumerate(prefs)}
                     for prefs in hospital_lists]
    assignment = [-1] * residents
    next_choice = [0] * residents
    while True:
        proposals: list[list[int]] = [[] for _ in range(hospitals)]
        for resident in range(residents):
            if assignment[resident] == -1 and next_choice[resident] < len(resident_lists[resident]):
                hospital = resident_lists[resident][next_choice[resident]]
                next_choice[resident] += 1
                proposals[hospital].append(resident)
        if not any(proposals):
            break
        candidates: list[list[int]] = [[] for _ in range(hospitals)]
        for resident, hospital in enumerate(assignment):
            if hospital != -1:
                candidates[hospital].append(resident)
        for hospital in range(hospitals):
            candidates[hospital].extend(proposals[hospital])
            candidates[hospital].sort(key=hospital_rank[hospital].__getitem__)
            for resident in candidates[hospital][:capacity_by_hospital[hospital]]:
                assignment[resident] = hospital
            for resident in candidates[hospital][capacity_by_hospital[hospital]:]:
                assignment[resident] = -1
    output = b"".join(struct.pack("<q", hospital) for hospital in assignment)
    return len(output), output
