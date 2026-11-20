"""Direct-resident-scan model, independent of the hop-information bitmap."""

from __future__ import annotations

from collections.abc import Sequence

SLOTS = 16
H = 4
STEP_LIMIT = 32
WORD_LIMIT = 1 + 3 * STEP_LIMIT


def _decode(frame: Sequence[int] | None):
    if not isinstance(frame, (list, tuple)) or len(frame) < 1 or len(frame) > WORD_LIMIT:
        return None
    for item in frame:
        if type(item) is not int or item < -(1 << 63) or item >= (1 << 63):
            return None
    amount = frame[0]
    if amount < 0 or amount > STEP_LIMIT or 1 + amount * 3 != len(frame):
        return None
    ops = []
    key_origin: list[int | None] = [None] * 64
    cursor = 1
    while cursor < len(frame):
        action, label, origin = frame[cursor], frame[cursor + 1], frame[cursor + 2]
        cursor += 3
        if action != 1 and action != 2:
            return None
        if label < 0 or label >= 64 or origin < 0 or origin >= SLOTS:
            return None
        if key_origin[label] is not None and key_origin[label] != origin:
            return None
        key_origin[label] = origin
        ops.append((action, label, origin))
    return ops


def _model(ops: list[tuple[int, int, int]]) -> bytes:
    table: list[tuple[int, int] | None] = [None for _ in range(SLOTS)]
    results = bytearray()

    def gap(origin: int, place: int) -> int:
        return (place - origin) % SLOTS

    def has(label: int, origin: int) -> bool:
        for record in table:
            if record is not None and record[0] == label and record[1] == origin:
                return True
        return False

    def place(label: int, origin: int) -> int:
        if has(label, origin):
            return 2
        empty = None
        for trial in range(SLOTS):
            index = (origin + trial) % SLOTS
            if table[index] is None:
                empty = index
                break
        if empty is None:
            return 0
        radius = gap(origin, empty)
        while radius >= H:
            shifted = False
            # Candidate homes run oldest-to-newest before the hole.
            for delta in range(H - 1, 0, -1):
                base = (empty - delta) % SLOTS
                new_distance = gap(base, empty)
                if gap(origin, base) >= radius:
                    continue
                eligible: list[tuple[int, int]] = []
                for cell, record in enumerate(table):
                    if record is None or record[1] != base:
                        continue
                    old_distance = gap(base, cell)
                    if old_distance < new_distance and gap(origin, cell) < radius:
                        eligible.append((old_distance, cell))
                if eligible:
                    _, old_cell = min(eligible)
                    table[empty] = table[old_cell]
                    table[old_cell] = None
                    empty = old_cell
                    radius = gap(origin, empty)
                    shifted = True
                    break
            if not shifted:
                return 0
        table[empty] = (label, origin)
        return 1

    for action, label, origin in ops:
        if action == 1:
            results.append(place(label, origin))
        else:
            results.append(1 if has(label, origin) else 0)
    contents = bytes(0 if entry is None else entry[0] + 1 for entry in table)
    masks = bytearray(SLOTS)
    for index, record in enumerate(table):
        if record is not None:
            origin = record[1]
            masks[origin] |= 1 << gap(origin, index)
    return bytes(results) + contents + bytes(masks)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0 or input_length > WORD_LIMIT):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    result = _model(decoded)
    if output_is_null or (capacity is not None and capacity < len(result)):
        return -2, b""
    return len(result), result
