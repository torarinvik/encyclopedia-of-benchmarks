"""Gusfield--Wu reduction with explicit preprocessing for missing states."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TAXA = 8
MAX_CHARACTERS = 8
MAX_VALID_INPUT_LENGTH = 66
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = 67
WORKSPACE_BYTES = 8192
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    taxa, characters = values[:2]
    if not 1 <= taxa <= MAX_TAXA or not 0 <= characters <= MAX_CHARACTERS:
        return None
    if len(values) != 2 + taxa * characters:
        return None
    matrix = values[2:]
    if any(value not in (0, 1, 2) for value in matrix):
        return None
    return taxa, characters, matrix


def _satisfiable(vertex_count: int, clauses: list[tuple[int, int]]) -> bool:
    literal_count = 2 * vertex_count
    graph = [[] for _ in range(literal_count)]
    reverse = [[] for _ in range(literal_count)]

    def add_arc(source: int, target: int) -> None:
        graph[source].append(target)
        reverse[target].append(source)

    for left, right in clauses:
        add_arc(left ^ 1, right)
        add_arc(right ^ 1, left)

    visited = [False] * literal_count
    order: list[int] = []

    def visit(vertex: int) -> None:
        visited[vertex] = True
        for neighbor in graph[vertex]:
            if not visited[neighbor]:
                visit(neighbor)
        order.append(vertex)

    for vertex in range(literal_count):
        if not visited[vertex]:
            visit(vertex)

    component = [-1] * literal_count

    def assign(vertex: int, label: int) -> None:
        component[vertex] = label
        for neighbor in reverse[vertex]:
            if component[neighbor] == -1:
                assign(neighbor, label)

    label = 0
    for vertex in reversed(order):
        if component[vertex] == -1:
            assign(vertex, label)
            label += 1
    return all(component[2 * variable] != component[2 * variable + 1]
               for variable in range(vertex_count))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return 1 iff the bounded three-state matrix has a perfect phylogeny."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    taxa, characters, matrix = parsed
    # Bit i records taxa i having the corresponding original character state.
    state_masks = [[0, 0, 0] for _ in range(characters)]
    for taxon in range(taxa):
        for character in range(characters):
            state = matrix[taxon * characters + character]
            state_masks[character][state] |= 1 << taxon

    # Variable (character,state) is character*3+state. Even literal IDs are
    # positive variables; the low bit toggles polarity.
    clauses: list[tuple[int, int]] = []
    for character in range(characters):
        variables = [2 * (3 * character + state) for state in range(3)]
        clauses.extend([(variables[0], variables[1]),
                        (variables[0], variables[2]),
                        (variables[1], variables[2])])
        present_states = [state for state in range(3) if state_masks[character][state]]
        if len(present_states) == 2:
            missing_state = next(state for state in range(3)
                                 if state not in present_states)
            missing_variable = 3 * character + missing_state
            negative_literal = 2 * missing_variable + 1
            # Do not let an absent column substitute for an observed column.
            clauses.append((negative_literal, negative_literal))

    universe = (1 << taxa) - 1
    for left_character in range(characters):
        for right_character in range(left_character + 1, characters):
            for left_state in range(3):
                left = state_masks[left_character][left_state]
                for right_state in range(3):
                    right = state_masks[right_character][right_state]
                    both = left & right
                    left_only = left & (universe ^ right)
                    right_only = right & (universe ^ left)
                    neither = universe ^ (left | right)
                    if both and left_only and right_only and neither:
                        left_variable = 3 * left_character + left_state
                        right_variable = 3 * right_character + right_state
                        clauses.append((2 * left_variable + 1,
                                        2 * right_variable + 1))

    return int(_satisfiable(3 * characters, clauses))


expected = expected_result
