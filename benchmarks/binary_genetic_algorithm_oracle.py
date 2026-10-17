"""Deterministic bounded port of the pinned binary genetic algorithm."""

from __future__ import annotations

import math

MAX_VALID_INPUT_LENGTH = 4
MAX_INPUT_LENGTH = 5
MAX_I64 = (1 << 63) - 1
MASK64 = (1 << 64) - 1
GOLDEN = 0x9E3779B97F4A7C15


class _SplitMix64:
    def __init__(self, seed: int) -> None:
        self.state = seed & MASK64

    def next_u64(self) -> int:
        self.state = (self.state + GOLDEN) & MASK64
        value = self.state
        value = ((value ^ (value >> 30)) * 0xBF58476D1CE4E5B9) & MASK64
        value = ((value ^ (value >> 27)) * 0x94D049BB133111EB) & MASK64
        return value ^ (value >> 31)

    def bounded(self, bound: int) -> int:
        """Unbiased draw in [0, bound), consuming a word even when bound is one."""
        threshold = (1 << 64) % bound
        while True:
            value = self.next_u64()
            if value >= threshold:
                return value % bound

    def unit(self) -> float:
        return (self.next_u64() >> 11) / float(1 << 53)


def _cost(candidate: int) -> int:
    return bin(candidate).count("1")


def _select_parent(probabilities: list[float], total: float, rng: _SplitMix64) -> int:
    target = rng.unit() * total
    cumulative = 0.0
    for index, probability in enumerate(probabilities):
        cumulative += probability
        if target <= cumulative:
            return index
    return len(probabilities) - 1


def _cross(first: int, second: int, n_var: int, rng: _SplitMix64) -> tuple[int, int]:
    kind = rng.bounded(3)
    child1 = 0
    child2 = 0
    if kind == 0:
        cut = rng.bounded(n_var - 1) + 1
        for gene in range(n_var):
            source1, source2 = (first, second) if gene < cut else (second, first)
            child1 |= ((source1 >> gene) & 1) << gene
            child2 |= ((source2 >> gene) & 1) << gene
    elif kind == 1:
        low = rng.bounded(n_var) + 1
        high = rng.bounded(n_var - 1) + 1
        if high >= low:
            high += 1
        if high < low:
            low, high = high, low
        for gene in range(n_var):
            if low <= gene < high:
                source1, source2 = second, first
            else:
                source1, source2 = first, second
            child1 |= ((source1 >> gene) & 1) << gene
            child2 |= ((source2 >> gene) & 1) << gene
    else:
        for gene in range(n_var):
            if rng.bounded(2) == 1:
                source1, source2 = first, second
            else:
                source1, source2 = second, first
            child1 |= ((source1 >> gene) & 1) << gene
            child2 |= ((source2 >> gene) & 1) << gene
    return child1, child2


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    seed, n_var_value, n_pop_value, max_it_value = values
    if not 0 <= seed <= MAX_I64:
        return -1
    if not 2 <= n_var_value <= 32:
        return -1
    if not 2 <= n_pop_value <= 16 or n_pop_value % 2 != 0:
        return -1
    if not 1 <= max_it_value <= 32:
        return -1

    n_var = n_var_value
    n_pop = n_pop_value
    max_it = max_it_value
    rng = _SplitMix64(seed)

    # MATLAB initializes candidates member-major, with genes in ascending order.
    population = []
    best_cost = n_var + 1
    for _ in range(n_pop):
        candidate = 0
        for gene in range(n_var):
            candidate |= rng.bounded(2) << gene
        population.append(candidate)
        candidate_cost = _cost(candidate)
        if candidate_cost < best_cost:
            best_cost = candidate_cost

    for _ in range(max_it):
        costs = [_cost(candidate) for candidate in population]
        average = sum(costs) / n_pop
        probabilities = [math.exp(-(cost / average if average != 0.0 else cost))
                         for cost in costs]
        probability_total = sum(probabilities)

        # popc is an nPop/2 by 2 MATLAB matrix; (: ) is column-major.
        first_children: list[int] = []
        second_children: list[int] = []
        for _pair in range(n_pop // 2):
            first_parent = population[_select_parent(probabilities, probability_total, rng)]
            second_parent = population[_select_parent(probabilities, probability_total, rng)]
            child1, child2 = _cross(first_parent, second_parent, n_var, rng)
            first_children.append(child1)
            second_children.append(child2)

        offspring = first_children + second_children
        for index, candidate in enumerate(offspring):
            for gene in range(n_var):
                if rng.unit() < 0.02:
                    candidate ^= 1 << gene
            offspring[index] = candidate
            candidate_cost = _cost(candidate)
            if candidate_cost < best_cost:
                best_cost = candidate_cost

        # The pinned SortPopulation helper sorts ascending by cost. Preserve
        # merged input order for equal costs, matching stable numeric sort.
        merged = population + offspring
        merged.sort(key=_cost)
        population = merged[:n_pop]

    return best_cost
