"""Clean-room reference for the fixed-buffer external-quicksort profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 1024
BUFFER_SIZE = 8
MAX_RECURSION_FRAMES = 12
MAX_WORKSPACE_BYTES = BUFFER_SIZE * MAX_RECURSION_FRAMES * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _sort_buffer(buffer: list[int]) -> None:
    for index in range(1, len(buffer)):
        value = buffer[index]
        position = index
        while position > 0 and value < buffer[position - 1]:
            buffer[position] = buffer[position - 1]
            position -= 1
        buffer[position] = value


def _sort_range(values: list[int], first: int, last: int) -> None:
    while last > first:
        read_low = write_low = first
        read_high = write_high = last
        buffer: list[int] = []
        max_lower: int | None = None
        min_upper: int | None = None
        lower_written_bound = first - 1
        upper_written_bound = last + 1

        while read_high >= read_low:
            if read_low - write_low < write_high - read_high:
                incoming = values[read_low]
                read_low += 1
            else:
                incoming = values[read_high]
                read_high -= 1

            if len(buffer) < BUFFER_SIZE:
                buffer.append(incoming)
                _sort_buffer(buffer)
            elif incoming > buffer[-1]:
                if min_upper is not None and incoming > min_upper:
                    upper_written_bound = write_high
                else:
                    min_upper = incoming
                values[write_high] = incoming
                write_high -= 1
            elif incoming < buffer[0]:
                if max_lower is not None and incoming < max_lower:
                    lower_written_bound = write_low
                else:
                    max_lower = incoming
                values[write_low] = incoming
                write_low += 1
            elif write_low - first < last - write_high:
                outgoing = buffer.pop(0)
                values[write_low] = outgoing
                write_low += 1
                max_lower = outgoing
                buffer.append(incoming)
                _sort_buffer(buffer)
            else:
                outgoing = buffer.pop()
                values[write_high] = outgoing
                write_high -= 1
                min_upper = outgoing
                buffer.append(incoming)
                _sort_buffer(buffer)

        while buffer:
            values[write_high] = buffer.pop()
            write_high -= 1

        if lower_written_bound - first < last - upper_written_bound:
            _sort_range(values, first, lower_written_bound)
            first = upper_written_bound
        else:
            _sort_range(values, upper_written_bound, last)
            last = lower_written_bound


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        raise ValueError("external quicksort accepts at most 1024 signed 64-bit values")
    result = list(values)
    if result:
        _sort_range(result, 0, len(result) - 1)
    return result
