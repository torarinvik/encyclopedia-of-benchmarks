"""Independent direct-set semantics for the sparse-set trace benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 30
MAX_PARSEABLE_INPUT_LENGTH = 63
INVALID_RESULT = -1


def _read(words: Sequence[int] | None, is_null: bool,
          supplied_length: int | None) -> tuple[int, tuple[tuple[int, int], ...]] | None:
    if (type(is_null) is not bool or is_null
            or not isinstance(words, (list, tuple))
            or not 2 <= len(words) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in words)):
        return None
    actual_length = len(words)
    if supplied_length is None:
        supplied_length = actual_length
    if type(supplied_length) is not int or supplied_length != actual_length:
        return None
    universe = words[0]
    count = words[1]
    if universe < 1 or universe > 32 or count < 0 or count > MAX_OPERATIONS:
        return None
    if actual_length != 2 + 2 * count:
        return None
    trace = []
    for offset in range(2, actual_length, 2):
        op, key = words[offset], words[offset + 1]
        if op not in (0, 1, 2, 3) or key < 0 or key >= universe:
            return None
        if op == 3 and key != 0:
            return None
        trace.append((op, key))
    return universe, tuple(trace)


def expected_result(words: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(words, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    universe, trace = parsed
    members: set[int] = set()
    answer_bits = 0
    for opcode, key in trace:
        if opcode == 0:
            answer = key not in members
            members.add(key)
        elif opcode == 1:
            answer = key in members
            members.discard(key)
        elif opcode == 2:
            answer = key in members
        else:
            answer = bool(members)
            members.clear()
        answer_bits = (answer_bits << 1) | int(answer)
    final_mask = sum(1 << key for key in members)
    return (final_mask << len(trace)) | answer_bits


def verify_candidate(words: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return type(result) is int and result == expected_result(words, input_is_null, input_length)
