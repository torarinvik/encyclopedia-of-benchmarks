"""Primary sorted-interval oracle for the bounded interval-container profile."""

from __future__ import annotations

from typing import Sequence

MAX_OPERATIONS = 24
RECORD_WIDTH = 3
MAX_INPUT_LENGTH = 1 + MAX_OPERATIONS * RECORD_WIDTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
DOMAIN_END = 32


def _parse(values: Sequence[int]) -> list[tuple[int, int, int]]:
    if not values or len(values) > MAX_INPUT_LENGTH:
        raise ValueError("input length")
    count = values[0]
    if type(count) is not int or not 0 <= count <= MAX_OPERATIONS:
        raise ValueError("operation count")
    if len(values) != 1 + count * RECORD_WIDTH:
        raise ValueError("frame length")
    operations = []
    for offset in range(1, len(values), RECORD_WIDTH):
        opcode, left, right = values[offset : offset + RECORD_WIDTH]
        if type(opcode) is not int or opcode not in (0, 1):
            raise ValueError("opcode")
        if type(left) is not int or type(right) is not int:
            raise ValueError("endpoint type")
        if not 0 <= left <= right <= DOMAIN_END:
            raise ValueError("interval endpoints")
        operations.append((opcode, left, right))
    return operations


class IntervalContainer:
    def __init__(self) -> None:
        self.intervals: list[tuple[int, int]] = []

    def add(self, left: int, right: int) -> None:
        if left == right:
            return
        merged: list[tuple[int, int]] = []
        inserted = False
        for start, end in self.intervals:
            if end < left:
                merged.append((start, end))
            elif right < start:
                if not inserted:
                    merged.append((left, right))
                    inserted = True
                merged.append((start, end))
            else:
                left = min(left, start)
                right = max(right, end)
        if not inserted:
            merged.append((left, right))
        self.intervals = merged

    def remove(self, left: int, right: int) -> None:
        if left == right:
            return
        remaining: list[tuple[int, int]] = []
        for start, end in self.intervals:
            if end <= left or start >= right:
                remaining.append((start, end))
            else:
                if start < left:
                    remaining.append((start, left))
                if end > right:
                    remaining.append((right, end))
        self.intervals = remaining

    def covered(self) -> int:
        return sum(end - start for start, end in self.intervals)


def run(values: Sequence[int] | None) -> int:
    if values is None:
        return -1
    try:
        operations = _parse(values)
    except (ValueError, IndexError):
        return -1
    container = IntervalContainer()
    checksum = 0
    for index, (opcode, left, right) in enumerate(operations, start=1):
        if opcode == 0:
            container.add(left, right)
        else:
            container.remove(left, right)
        checksum += index * container.covered()
    return checksum


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if input_is_null or values is None:
        return -1
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > len(values)
            or input_length > MAX_PARSEABLE_INPUT_LENGTH):
        return -1
    return run(values[:input_length])
