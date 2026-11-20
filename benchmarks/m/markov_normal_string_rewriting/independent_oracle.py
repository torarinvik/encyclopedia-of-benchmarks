"""Occurrence-enumerating reference for the bounded normal-algorithm profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_RULES = 8
MAX_STEPS = 32
MAX_INITIAL_WORD = 48
MAX_RULE_SIDE = 8
MAX_WORD = 64
MAX_PARSEABLE_INPUT_LENGTH = 204
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[int], list[tuple[int, list[int], list[int]]], int] | None:
    if (input_is_null is not False or values is None
            or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    count, budget, text_size = values[0], values[1], values[2]
    if not 0 <= count <= MAX_RULES or not 0 <= budget <= MAX_STEPS or not 0 <= text_size <= MAX_INITIAL_WORD:
        return None
    pos = 3
    if pos + text_size > len(values):
        return None
    text = list(values[pos:pos + text_size])
    pos += text_size
    if any(symbol < 0 or symbol > 25 for symbol in text):
        return None

    rules: list[tuple[int, list[int], list[int]]] = []
    for _index in range(count):
        if len(values) - pos < 3:
            return None
        stop_flag, before_size, after_size = values[pos], values[pos + 1], values[pos + 2]
        pos += 3
        if stop_flag not in (0, 1) or not 1 <= before_size <= MAX_RULE_SIDE or not 0 <= after_size <= MAX_RULE_SIDE:
            return None
        end = pos + before_size + after_size
        if end > len(values):
            return None
        before = list(values[pos:pos + before_size])
        after = list(values[pos + before_size:end])
        pos = end
        if any(c < 0 or c > 25 for c in before + after):
            return None
        rules.append((stop_flag, before, after))
    if pos != len(values):
        return None
    return text, rules, budget


def _select_every_occurrence(text: list[int], rules: list[tuple[int, list[int], list[int]]]) -> tuple[int, int] | None:
    best: tuple[int, int] | None = None
    for rule_id, (_, needle, _) in enumerate(rules):
        final_start = len(text) - len(needle)
        if final_start < 0:
            continue
        for offset in range(final_start + 1):
            equal = True
            for k in range(len(needle)):
                if text[offset + k] != needle[k]:
                    equal = False
                    break
            candidate = (rule_id, offset)
            if equal and (best is None or candidate < best):
                best = candidate
    return best


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    text, rules, budget = decoded
    applied = 0
    halt = 0
    while True:
        candidates = _select_every_occurrence(text, rules)
        if candidates is None:
            halt = 0
            break
        if applied == budget:
            halt = 2
            break
        rule_id, offset = candidates
        stop_flag, before, after = rules[rule_id]
        replacement = text[:offset] + after + text[offset + len(before):]
        if len(replacement) > MAX_WORD:
            return -3, b""
        text = replacement
        applied += 1
        if stop_flag:
            halt = 1
            break
    result = bytes((halt, applied, len(text), *text))
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
