"""Barbay-Kenyon Algorithm 3 specialized to three lists and threshold two."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LIST_LENGTH = 32
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_LIST_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_MATCHES = 3 * MAX_LIST_LENGTH // 2
MAX_OUTPUT_BYTES = 8 * (1 + MAX_MATCHES)
WORKSPACE_BYTES = 8192
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def _parse(values: Sequence[int]):
    if len(values) < 6 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    lists: list[tuple[int, ...]] = []
    at = 0
    for _ in range(3):
        if at >= len(values):
            return None
        size = values[at]
        at += 1
        if not 1 <= size <= MAX_LIST_LENGTH or at + size > len(values):
            return None
        items = tuple(values[at:at + size])
        if (any(item < I32_MIN or item > I32_MAX for item in items)
                or any(items[index - 1] >= items[index] for index in range(1, size))):
            return None
        lists.append(items)
        at += size
    if at != len(values):
        return None
    return lists


def _matches(lists: Sequence[Sequence[int]]) -> list[int]:
    # k=3,t=2. H is represented by the at-most-three red representatives;
    # a stable list-ID scan chooses its minimum.
    maxima = sorted(items[-1] for items in lists)
    maximum_candidate = maxima[-2]
    heads = [items[0] for items in lists]
    candidate = sorted(heads)[1]

    color = ["white"] * 3
    cursor = [0] * 3
    search_base = [0] * 3
    search_low = [0] * 3
    search_step = [1] * 3
    search_probe = [0] * 3
    representative_index = [-1] * 3
    representative_present = [False] * 3

    for list_id, items in enumerate(lists):
        cursor[list_id] = 1
        search_base[list_id] = 1
        search_low[list_id] = 1
        search_probe[list_id] = 1
        if heads[list_id] == candidate:
            color[list_id] = "green"
        elif heads[list_id] > candidate:
            color[list_id] = "red"
            representative_index[list_id] = 0
            representative_present[list_id] = True

    result: list[int] = []
    round_robin = 0
    while candidate <= maximum_candidate:
        green = [i for i in range(3) if color[i] == "green"]
        red = [i for i in range(3) if color[i] == "red"]
        white = [i for i in range(3) if color[i] == "white"]

        if len(green) >= 2 or len(red) >= 2:
            if len(green) >= 2:
                result.append(candidate)

            # Algorithm 3 keeps at most t-1=1 white set. When none exists,
            # recolor one green set white; otherwise preserve the existing one.
            recolor_count = 1 - len(white)
            kept_white = set(sorted(green)[:recolor_count])
            for list_id in green:
                if list_id in kept_white:
                    color[list_id] = "white"
                    search_base[list_id] = cursor[list_id]
                    search_low[list_id] = cursor[list_id]
                    search_step[list_id] = 1
                    search_probe[list_id] = cursor[list_id]
                else:
                    color[list_id] = "red"
                    representative_index[list_id] = cursor[list_id]
                    representative_present[list_id] = cursor[list_id] < len(lists[list_id])

            available = [i for i in range(3) if color[i] == "red"
                         and representative_present[i]]
            if not available:
                break
            candidate = min((lists[i][representative_index[i]], i)
                            for i in available)[0]
            for list_id in available:
                if lists[list_id][representative_index[list_id]] == candidate:
                    color[list_id] = "green"
                    representative_present[list_id] = False
                    cursor[list_id] = representative_index[list_id] + 1
                    search_base[list_id] = cursor[list_id]
                    search_low[list_id] = cursor[list_id]
                    search_step[list_id] = 1
                    search_probe[list_id] = cursor[list_id]
            continue

        if not white:
            break
        list_id = None
        for offset in range(3):
            possible = (round_robin + offset) % 3
            if color[possible] == "white":
                list_id = possible
                break
        if list_id is None:
            break
        round_robin = (list_id + 1) % 3
        items = lists[list_id]
        probe = min(search_probe[list_id], len(items) - 1)
        if items[probe] < candidate:
            search_low[list_id] = probe + 1
            if probe == len(items) - 1:
                color[list_id] = "red"
                representative_index[list_id] = len(items)
                representative_present[list_id] = False
            else:
                search_step[list_id] *= 2
                search_probe[list_id] = min(
                    search_base[list_id] + search_step[list_id] - 1,
                    len(items) - 1,
                )
            continue

        low = search_low[list_id]
        high = probe + 1
        while low < high:
            middle = (low + high) // 2
            if items[middle] < candidate:
                low = middle + 1
            else:
                high = middle
        if low < len(items) and items[low] == candidate:
            color[list_id] = "green"
            cursor[list_id] = low + 1
        else:
            color[list_id] = "red"
            representative_index[list_id] = low
            representative_present[list_id] = low < len(items)
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    lists = _parse(values)
    if lists is None:
        return -1, b""
    matches = _matches(lists)
    payload = b"".join(struct.pack("<q", word)
                       for word in [len(matches), *matches])
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
