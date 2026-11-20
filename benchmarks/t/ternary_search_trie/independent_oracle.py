"""Independent direct-dictionary oracle for the ternary-search-trie profile."""

from __future__ import annotations

from typing import Sequence

MAX_OPERATIONS = 64
MAX_KEY_LENGTH = 6
RECORD_WIDTH = MAX_KEY_LENGTH + 3
MAX_INPUT_VALUES = 1 + MAX_OPERATIONS * RECORD_WIDTH
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_VALUES + 1
MAX_VALUE = 65_535


def _parse(values: Sequence[int]) -> list[tuple[int, str, int]]:
    if not values or len(values) > MAX_PARSEABLE_INPUT_VALUES:
        raise ValueError("input length")
    count = values[0]
    if not isinstance(count, int) or count < 0 or count > MAX_OPERATIONS:
        raise ValueError("operation count")
    if len(values) != 1 + count * RECORD_WIDTH:
        raise ValueError("frame length")
    operations: list[tuple[int, str, int]] = []
    offset = 1
    for _ in range(count):
        record = values[offset : offset + RECORD_WIDTH]
        offset += RECORD_WIDTH
        opcode, key_length = record[0], record[1]
        if not isinstance(opcode, int) or opcode < 0 or opcode > 6:
            raise ValueError("opcode")
        if not isinstance(key_length, int) or key_length < 0 or key_length > MAX_KEY_LENGTH:
            raise ValueError("key length")
        if opcode in (0, 1, 2) and key_length == 0:
            raise ValueError("empty key")
        if opcode == 6 and key_length != 0:
            raise ValueError("size key length")
        chars = record[2 : 2 + key_length]
        if any(not isinstance(c, int) or not (97 <= c <= 122 or opcode == 5 and c == 46) for c in chars):
            raise ValueError("character")
        if any(c != 0 for c in record[2 + key_length : 2 + MAX_KEY_LENGTH]):
            raise ValueError("padding")
        value = record[-1]
        if opcode == 0:
            if not isinstance(value, int) or value < 1 or value > MAX_VALUE:
                raise ValueError("value")
        elif value != 0:
            raise ValueError("unused value")
        operations.append((opcode, "".join(chr(c) for c in chars), value))
    return operations


def run(values: Sequence[int] | None) -> int:
    if values is None:
        return -1
    try:
        operations = _parse(values)
    except (ValueError, IndexError):
        return -1
    table: dict[str, int] = {}
    total = 0
    for index, (opcode, key, value) in enumerate(operations, start=1):
        if opcode == 0:
            observed = table.get(key, 0)
            table[key] = value
        elif opcode == 1:
            observed = table.get(key, 0)
        elif opcode == 2:
            observed = table.pop(key, 0)
        elif opcode == 3:
            observed = max((size for size in range(1, len(key) + 1) if key[:size] in table), default=0)
        elif opcode == 4:
            observed = sum(candidate.startswith(key) for candidate in table)
        elif opcode == 5:
            observed = sum(
                len(candidate) == len(key)
                and all(expected == "." or expected == actual for expected, actual in zip(key, candidate))
                for candidate in table
            )
        else:
            observed = len(table)
        total += index * observed
    return total


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if input_is_null or values is None:
        return -1
    if input_length is None:
        input_length = len(values)
    if input_length < 0 or input_length > len(values) or input_length > MAX_PARSEABLE_INPUT_VALUES:
        return -1
    return run(values[:input_length])
