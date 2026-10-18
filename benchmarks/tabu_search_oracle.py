"""Oracle for the pinned source-ordered symmetric-TSP tabu search."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_CITIES = 4
MAX_CITIES = 6
MAX_ITERATIONS = 8
MIN_TABU_SIZE = 1
MAX_TABU_SIZE = 3
MIN_WEIGHT = 1
MAX_WEIGHT = 99
MAX_INPUT_LENGTH = 3 + MAX_CITIES * (MAX_CITIES - 1) // 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * (MAX_CITIES + 3)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the source's best tour and cost as little-endian i32 words."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""

    city_count, iterations, tabu_size = values[:3]
    if not MIN_CITIES <= city_count <= MAX_CITIES:
        return INVALID_RESULT, b""
    if not 0 <= iterations <= MAX_ITERATIONS:
        return INVALID_RESULT, b""
    if not MIN_TABU_SIZE <= tabu_size <= MAX_TABU_SIZE:
        return INVALID_RESULT, b""
    edge_count = city_count * (city_count - 1) // 2
    if len(values) != 3 + edge_count:
        return INVALID_RESULT, b""
    weights = values[3:]
    if any(not MIN_WEIGHT <= weight <= MAX_WEIGHT for weight in weights):
        return INVALID_RESULT, b""

    neighbors: list[list[tuple[int, int]]] = [[] for _ in range(city_count)]
    edge_cost: dict[tuple[int, int], int] = {}
    offset = 0
    for left in range(city_count):
        for right in range(left + 1, city_count):
            weight = weights[offset]
            offset += 1
            neighbors[left].append((right, weight))
            neighbors[right].append((left, weight))
            edge_cost[left, right] = edge_cost[right, left] = weight

    # Greedy starting tour. The graph bounds ensure every unvisited lookup exists
    # and the source's 10000 sentinel cannot beat an actual edge.
    current = 0
    initial: list[int] = []
    while current not in initial:
        minimum = 10_000
        best_node = current
        for node, weight in neighbors[current]:
            if weight < minimum and node not in initial:
                minimum = weight
                best_node = node
        initial.append(current)
        current = best_node
    initial.append(0)
    best_cost = sum(edge_cost[a, b] for a, b in zip(initial, initial[1:]))
    solution = initial
    best_solution = initial
    tabu: list[tuple[int, int]] = []

    for _ in range(iterations):
        neighborhood: list[list[int]] = []
        for first in solution[1:-1]:
            first_index = solution.index(first)
            for second in solution[1:-1]:
                second_index = solution.index(second)
                if first == second:
                    continue
                candidate = solution.copy()
                candidate[first_index], candidate[second_index] = (
                    candidate[second_index], candidate[first_index]
                )
                cost = sum(
                    edge_cost[a, b] for a, b in zip(candidate, candidate[1:])
                )
                candidate.append(cost)
                if candidate not in neighborhood:
                    neighborhood.append(candidate)
        neighborhood.sort(key=lambda candidate: candidate[-1])

        selected_index = 0
        while True:
            candidate = neighborhood[selected_index]
            for index, (new, old) in enumerate(zip(candidate, solution)):
                if new != old:
                    exchange = (new, old)
                    break
            if exchange not in tabu and (exchange[1], exchange[0]) not in tabu:
                tabu.append(exchange)
                solution = candidate[:-1]
                cost = candidate[-1]
                if cost < best_cost:
                    best_cost = cost
                    best_solution = solution
                break
            selected_index += 1
        if len(tabu) >= tabu_size:
            tabu.pop(0)

    words = [len(best_solution), *best_solution, best_cost]
    output = struct.pack("<" + "i" * len(words), *words)
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
