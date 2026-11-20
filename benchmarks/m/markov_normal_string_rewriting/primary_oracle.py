"""Rule-priority interpreter for a bounded Markov normal algorithm."""

from __future__ import annotations

from collections.abc import Sequence

MAX_RULES = 8
MAX_STEPS = 32
MAX_INITIAL_WORD = 48
MAX_SIDE = 8
MAX_WORD = 64
MAX_VALID_INPUT_LENGTH = 203
MAX_PARSEABLE_INPUT_LENGTH = 204
MAX_OUTPUT_BYTES = 67
WORKSPACE_BYTES = 4096
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[tuple[int, tuple[int, ...], tuple[int, ...]]], int] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if (input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    rule_count, step_limit, word_length = values[:3]
    if (not 0 <= rule_count <= MAX_RULES or not 0 <= step_limit <= MAX_STEPS
            or not 0 <= word_length <= MAX_INITIAL_WORD
            or len(values) < 3 + word_length):
        return None
    cursor = 3
    word = list(values[cursor:cursor + word_length])
    cursor += word_length
    if any(not 0 <= symbol <= 25 for symbol in word):
        return None

    rules: list[tuple[int, tuple[int, ...], tuple[int, ...]]] = []
    for _ in range(rule_count):
        if cursor + 3 > len(values):
            return None
        kind, lhs_length, rhs_length = values[cursor:cursor + 3]
        cursor += 3
        if (kind not in (0, 1) or not 1 <= lhs_length <= MAX_SIDE
                or not 0 <= rhs_length <= MAX_SIDE
                or cursor + lhs_length + rhs_length > len(values)):
            return None
        lhs = tuple(values[cursor:cursor + lhs_length])
        cursor += lhs_length
        rhs = tuple(values[cursor:cursor + rhs_length])
        cursor += rhs_length
        if any(not 0 <= symbol <= 25 for symbol in (*lhs, *rhs)):
            return None
        rules.append((kind, lhs, rhs))
    if cursor != len(values):
        return None
    return word, rules, step_limit


def _first_rule_match(word: list[int], rules: list[tuple[int, tuple[int, ...], tuple[int, ...]]]) -> tuple[int, int] | None:
    for rule_index, (_, lhs, _) in enumerate(rules):
        last_start = len(word) - len(lhs)
        for start in range(last_start + 1):
            if tuple(word[start:start + len(lhs)]) == lhs:
                return rule_index, start
    return None


def _run(word: list[int], rules: list[tuple[int, tuple[int, ...], tuple[int, ...]]],
         step_limit: int) -> tuple[int, int, list[int]] | None:
    steps = 0
    while True:
        selected = _first_rule_match(word, rules)
        if selected is None:
            return 0, steps, word
        if steps == step_limit:
            return 2, steps, word
        rule_index, start = selected
        kind, lhs, rhs = rules[rule_index]
        updated = word[:start] + list(rhs) + word[start + len(lhs):]
        if len(updated) > MAX_WORD:
            return None
        word = updated
        steps += 1
        if kind == 1:
            return 1, steps, word


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return status and framed output bytes without writing to a caller buffer."""
    if (type(output_is_null) is not bool or (capacity is not None
            and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    word, rules, step_limit = parsed
    completed = _run(word, rules, step_limit)
    if completed is None:
        return -3, b""
    halt, steps, final_word = completed
    encoded = bytes((halt, steps, len(final_word), *final_word))
    if output_is_null or (capacity is not None and capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
