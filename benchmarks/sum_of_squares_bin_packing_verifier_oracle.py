"""Independent verifier for the bounded DOI 49 Sum-of-Squares profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 66


def _objective(bins: Sequence[int], capacity: int) -> int:
    occupancy = [0 for _ in range(capacity + 1)]
    for load in bins:
        if 0 < load < capacity:
            occupancy[load] += 1
    total = 0
    for count in occupancy[1:capacity]:
        total += count * count
    return total


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    capacity, count = values[0], values[1]
    if not 1 <= capacity <= 64 or not 0 <= count <= 64 or len(values) != count + 2:
        return -1, b""
    pending = list(values[2:])
    if any(size < 1 or size > capacity for size in pending):
        return -1, b""
    bin_loads: list[int] = []
    placement: list[int] = []
    for item_size in pending:
        chosen_bin = len(bin_loads)
        chosen_score: int | None = None
        for candidate_id in range(len(bin_loads) + 1):
            if candidate_id < len(bin_loads) and bin_loads[candidate_id] + item_size > capacity:
                continue
            proposed = bin_loads.copy()
            if candidate_id == len(bin_loads):
                proposed.append(item_size)
            else:
                proposed[candidate_id] += item_size
            candidate_score = _objective(proposed, capacity)
            if chosen_score is None or candidate_score < chosen_score:
                chosen_score = candidate_score
                chosen_bin = candidate_id
        if chosen_bin == len(bin_loads):
            bin_loads.append(item_size)
        else:
            bin_loads[chosen_bin] += item_size
        placement.append(chosen_bin)
    output_words = [len(bin_loads)]
    output_words.extend(placement)
    encoded = bytearray()
    for word in output_words:
        encoded.extend(int(word).to_bytes(8, byteorder="little", signed=True))
    return len(encoded), bytes(encoded)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    status, data = evaluate(values)
    if status < 0:
        return status, data
    if output_is_null or capacity is not None and capacity < len(data):
        return -2, b""
    return status, data
