"""American-flag MSD distribution over bounded byte strings."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_STRINGS = 256
MAX_STRING_LENGTH = 32
RADIX = 257
MAX_VALID_INPUT_LENGTH = 1 + MAX_STRINGS * (MAX_STRING_LENGTH + 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 327_680


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values:
        return None

    count = values[0]
    if not 0 <= count <= MAX_STRINGS:
        return None
    cursor = 1
    strings: list[tuple[int, ...]] = []
    for _ in range(count):
        if cursor >= len(values):
            return None
        length = values[cursor]
        cursor += 1
        if not 0 <= length <= MAX_STRING_LENGTH or cursor + length > len(values):
            return None
        string = tuple(values[cursor:cursor + length])
        if any(not 0 <= byte <= 255 for byte in string):
            return None
        strings.append(string)
        cursor += length
    if cursor != len(values):
        return None
    return strings


def _american_flag_order(strings: list[tuple[int, ...]]) -> list[int]:
    order = list(range(len(strings)))

    def key(index: int, depth: int) -> int:
        string = strings[index]
        return string[depth] + 1 if depth < len(string) else 0

    def distribute(low: int, high: int, depth: int) -> None:
        if high - low < 2:
            return
        counts = [0] * RADIX
        for position in range(low, high):
            counts[key(order[position], depth)] += 1

        starts = [0] * RADIX
        ends = [0] * RADIX
        next_position = [0] * RADIX
        boundary = low
        for bucket, frequency in enumerate(counts):
            starts[bucket] = boundary
            boundary += frequency
            ends[bucket] = boundary
            next_position[bucket] = starts[bucket]

        for bucket in range(RADIX):
            while next_position[bucket] < ends[bucket]:
                destination_bucket = key(order[next_position[bucket]], depth)
                if destination_bucket == bucket:
                    next_position[bucket] += 1
                else:
                    destination = next_position[destination_bucket]
                    order[next_position[bucket]], order[destination] = (
                        order[destination], order[next_position[bucket]])
                    next_position[destination_bucket] += 1

        for bucket in range(1, RADIX):
            if ends[bucket] - starts[bucket] > 1:
                distribute(starts[bucket], ends[bucket], depth + 1)

    distribute(0, len(order), 0)
    return order


def _checksum(strings: list[tuple[int, ...]], order: list[int]) -> int:
    checksum = 0
    for rank, index in enumerate(order, start=1):
        string = strings[index]
        contribution = len(string) + 1 + sum(byte + 1 for byte in string)
        checksum += rank * contribution
    return checksum


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    strings = _decode(values, input_is_null, input_length)
    if strings is None:
        return -1
    return _checksum(strings, _american_flag_order(strings))
