"""Bounded Moore-style whole-partition DFA refinement reference."""

from collections.abc import Sequence

MAX_STATES = 8
MAX_ALPHABET = 3
MAX_VALID_INPUT_LENGTH = 4 + MAX_STATES * MAX_ALPHABET
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None) -> tuple[int, int, int, int, list[list[int]]] | None:
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, alphabet, start, accepting = values[:4]
    if not 1 <= n <= MAX_STATES or not 1 <= alphabet <= MAX_ALPHABET:
        return None
    if not 0 <= start < n or not 0 <= accepting < (1 << n):
        return None
    if len(values) != 4 + n * alphabet:
        return None
    transitions: list[list[int]] = []
    cursor = 4
    for _ in range(n):
        row = list(values[cursor:cursor + alphabet])
        if any(not 0 <= target < n for target in row):
            return None
        transitions.append(row)
        cursor += alphabet
    return n, alphabet, start, accepting, transitions


def _pack(labels: list[int], class_count: int, rounds: int) -> int:
    packed_labels = sum(label << (3 * state) for state, label in enumerate(labels))
    return (class_count << 28) | (rounds << 24) | packed_labels


def expected(values: Sequence[int] | None, input_is_null: bool = False,
             input_length: int | None = None) -> int:
    if type(input_is_null) is not bool:
        return -1
    if input_is_null:
        return -1
    if input_length is not None:
        if not isinstance(values, (list, tuple)) or type(input_length) is not int or input_length != len(values):
            return -1
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, alphabet, _, accepting, transitions = parsed
    labels = [0] * n
    seen_acceptance: dict[bool, int] = {}
    for state in range(n):
        is_accepting = bool(accepting & (1 << state))
        if is_accepting not in seen_acceptance:
            seen_acceptance[is_accepting] = len(seen_acceptance)
        labels[state] = seen_acceptance[is_accepting]

    rounds = 0
    while True:
        signature_ids: dict[tuple[int, ...], int] = {}
        refined: list[int] = []
        for state in range(n):
            signature = (labels[state], *(labels[transitions[state][symbol]] for symbol in range(alphabet)))
            if signature not in signature_ids:
                signature_ids[signature] = len(signature_ids)
            refined.append(signature_ids[signature])
        if refined == labels:
            class_count = len(signature_ids)
            break
        labels = refined
        rounds += 1
    return _pack(labels, class_count, rounds)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Scalar ABI adapter; output capacity is irrelevant to scalar results."""
    del capacity, output_is_null
    return expected(values, input_is_null=input_is_null, input_length=input_length)
