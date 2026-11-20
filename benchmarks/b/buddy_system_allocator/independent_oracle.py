"""Dyadic-interval reference, independent of the primary order-indexed tables."""

from __future__ import annotations

from collections.abc import Sequence

ARENA = 256
LIMIT = 64
TAG_LIMIT = 32
WORD_LIMIT = 1 + 3 * LIMIT + 1
MAX_OUTPUT_BYTES = (3 * LIMIT + 1 + 2 * ARENA) * 8
WORKSPACE_BYTES = 16_384


def _read_frame(frame: Sequence[int] | None):
    if not isinstance(frame, (list, tuple)) or not 1 <= len(frame) <= WORD_LIMIT:
        return None
    for value in frame:
        if type(value) is not int or not -(1 << 63) <= value < (1 << 63):
            return None
    total = frame[0]
    if total < 0 or total > LIMIT or len(frame) != 1 + 3 * total:
        return None
    records = []
    at = 1
    while at < len(frame):
        code, identifier, value = frame[at:at + 3]
        at += 3
        if identifier < 0 or identifier >= TAG_LIMIT:
            return None
        if code == 0:
            if value < 1 or value > ARENA:
                return None
        elif code == 1:
            if value != 0:
                return None
        else:
            return None
        records.append((code, identifier, value))
    return records


def _class_size(request: int) -> int:
    result = 1
    while result < request:
        result *= 2
    return result


def _run_intervals(records):
    available: list[tuple[int, int]] = [(0, ARENA)]
    holdings: dict[int, tuple[int, int]] = {}
    result_words: list[int] = []
    for code, identifier, amount in records:
        if code == 0:
            if identifier in holdings:
                return None
            wanted = _class_size(amount)
            chosen = None
            size = wanted
            while size <= ARENA and chosen is None:
                matching = [entry for entry in available if entry[1] == size]
                if matching:
                    chosen = min(matching, key=lambda entry: entry[0])
                size *= 2
            if chosen is None:
                result_words.extend((0, -1, 0))
                continue
            available.remove(chosen)
            base, size = chosen
            while size > wanted:
                size //= 2
                available.append((base + size, size))
            available.sort()
            holdings[identifier] = (base, wanted)
            result_words.extend((1, base, wanted))
        else:
            if identifier not in holdings:
                return None
            original_base, original_size = holdings.pop(identifier)
            base, size = original_base, original_size
            while size < ARENA:
                sibling_base = base ^ size
                sibling = (sibling_base, size)
                if sibling not in available:
                    break
                available.remove(sibling)
                base = min(base, sibling_base)
                size *= 2
            available.append((base, size))
            available.sort()
            result_words.extend((1, original_base, original_size))
    result_words.append(len(available))
    for base, size in available:
        result_words.extend((base, size))
    return result_words


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= WORD_LIMIT):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    records = _read_frame(values)
    if records is None:
        return -1, b""
    words = _run_intervals(records)
    if words is None:
        return -1, b""
    output = b"".join((item & ((1 << 64) - 1)).to_bytes(8, "little") for item in words)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
