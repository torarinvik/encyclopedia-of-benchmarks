"""Direct omitted-state enumeration for bounded at-most-three-state phylogeny."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product

MAX_TAXA = 8
MAX_CHARACTERS = 8
MAX_VALID_INPUT_LENGTH = 66
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = 67
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return -1
    taxa, characters = values[:2]
    if not 1 <= taxa <= MAX_TAXA or not 0 <= characters <= MAX_CHARACTERS:
        return -1
    if len(values) != 2 + taxa * characters:
        return -1
    matrix = values[2:]
    if any(value not in (0, 1, 2) for value in matrix):
        return -1

    # Build each expanded binary character as its taxa-membership set.
    columns = [[set() for _ in range(3)] for _ in range(characters)]
    for taxon in range(taxa):
        for character in range(characters):
            columns[character][matrix[taxon * characters + character]].add(taxon)

    def compatible(left: set[int], right: set[int]) -> bool:
        patterns = set()
        for taxon in range(taxa):
            patterns.add((taxon in left, taxon in right))
        return len(patterns) < 4

    # Enumerate omitted states independently of the implication graph. For a
    # two-state character, its missing column is forced false; constants are
    # dropped because they impose no compatibility constraint.
    for omitted in product(range(3), repeat=characters):
        selected = []
        choice_allowed = True
        for character in range(characters):
            present = [state for state in range(3) if columns[character][state]]
            if len(present) == 1:
                continue
            if len(present) == 2:
                missing = next(state for state in range(3) if state not in present)
                if omitted[character] != missing:
                    choice_allowed = False
                    break
                selected.extend((character, state) for state in present)
            else:
                selected.extend((character, state) for state in range(3)
                                if state != omitted[character])
        if not choice_allowed:
            continue
        valid = True
        for index, (left_character, left_state) in enumerate(selected):
            for right_character, right_state in selected[index + 1:]:
                if left_character == right_character:
                    continue
                if not compatible(columns[left_character][left_state],
                                  columns[right_character][right_state]):
                    valid = False
                    break
            if not valid:
                break
        if valid:
            return 1
    return 0


expected = expected_result
