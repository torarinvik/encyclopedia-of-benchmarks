"""Tuple-tag reference for observed-remove set traces."""

from __future__ import annotations

from collections.abc import Callable, Sequence

MAX_OPERATIONS = 32
MAX_ELEMENTS = 16


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual = len(values) if input_length is None else input_length
    if type(actual) is not int or actual != len(values) or not 1 <= actual <= 129:
        return None
    count = values[0]
    if type(count) is not int or not 0 <= count <= MAX_OPERATIONS or actual != 1 + 4 * count:
        return None
    operations = []
    for index in range(count):
        opcode, replica, element, peer = values[1 + 4 * index:5 + 4 * index]
        if opcode in (0, 1, 2):
            if not 0 <= replica < 2 or not 0 <= element < MAX_ELEMENTS or peer != 0:
                return None
        elif opcode in (3, 4):
            if not 0 <= replica < 2 or element != 0 or not 0 <= peer < 2:
                return None
        else:
            return None
        operations.append((opcode, replica, element, peer))
    return operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _parse(values, input_is_null, input_length)
    if operations is None:
        return -1

    # A tag is the pair (creator replica, that replica's add sequence number).
    observed_add_tags: list[set[tuple[int, int, int]]] = [set(), set()]
    removed_tags: list[set[tuple[int, int, int]]] = [set(), set()]
    sequence = [0, 0]
    answer = 0
    read_index = 0
    for opcode, replica, element, peer in operations:
        result = False
        if opcode == 0:
            tag = (element, replica, sequence[replica])
            sequence[replica] += 1
            observed_add_tags[replica].add(tag)
        elif opcode == 1:
            removed_tags[replica].update(
                tag for tag in observed_add_tags[replica]
                if tag[0] == element and tag not in removed_tags[replica]
            )
        elif opcode == 2:
            result = any(tag[0] == element and tag not in removed_tags[replica]
                         for tag in observed_add_tags[replica])
        elif opcode == 3:
            observed_add_tags[replica] = observed_add_tags[replica] | observed_add_tags[peer]
            removed_tags[replica] = removed_tags[replica] | removed_tags[peer]
        else:
            result = (observed_add_tags[replica] <= observed_add_tags[peer]
                      and removed_tags[replica] <= removed_tags[peer])
        if opcode in (2, 4):
            if result:
                answer |= 1 << read_index
            read_index += 1
    return answer


def verify_candidate(candidate: Callable[..., int], values: Sequence[int],
                     expected: int | None = None) -> bool:
    if expected is None:
        expected = expected_result(values)
    return candidate(values, len(values)) == expected
