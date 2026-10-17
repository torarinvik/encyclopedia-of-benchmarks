package binary_genetic_algorithm

import "core:c"
import "core:math"

MAX_POPULATION :: 16

next_word :: proc "contextless" (state: ^u64) -> u64 {
	state^ += 0x9E3779B97F4A7C15
	value := state^
	value = (value ^ (value >> 30)) * 0xBF58476D1CE4E5B9
	value = (value ^ (value >> 27)) * 0x94D049BB133111EB
	return value ^ (value >> 31)
}

bounded :: proc "contextless" (state: ^u64, bound: u64) -> u64 {
	threshold := (u64(0) - bound) % bound
	for {
		value := next_word(state)
		if value >= threshold do return value % bound
	}
}

unit_random :: proc "contextless" (state: ^u64) -> f64 {
	return f64(next_word(state) >> 11) / 9007199254740992.0
}

cost_of :: proc "contextless" (candidate: u64, n_var: int) -> i64 {
	cost := i64(0)
	for gene := 0; gene < n_var; gene += 1 {
		cost += i64((candidate >> u64(gene)) & 1)
	}
	return cost
}

select_parent :: proc "contextless" (probabilities: [^]f64, n_pop: int,
	total: f64, state: ^u64) -> int {
	target := unit_random(state) * total
	cumulative := 0.0
	for index := 0; index < n_pop; index += 1 {
		cumulative += probabilities[index]
		if target <= cumulative do return index
	}
	return n_pop - 1
}

crossover :: proc "contextless" (first, second: u64, n_var: int, state: ^u64,
	child1, child2: ^u64) {
	kind := bounded(state, 3)
	child1^ = 0
	child2^ = 0
	if kind == 0 {
		cut := int(bounded(state, u64(n_var - 1))) + 1
		for gene := 0; gene < n_var; gene += 1 {
			bit := u64(1) << u64(gene)
			if gene < cut {
				child1^ |= first & bit
				child2^ |= second & bit
			} else {
				child1^ |= second & bit
				child2^ |= first & bit
			}
		}
	} else if kind == 1 {
		low := int(bounded(state, u64(n_var))) + 1
		high := int(bounded(state, u64(n_var - 1))) + 1
		if high >= low do high += 1
		if high < low { temporary := low; low = high; high = temporary }
		for gene := 0; gene < n_var; gene += 1 {
			bit := u64(1) << u64(gene)
		exchange := gene >= low && gene < high
			if exchange {
				child1^ |= second & bit
				child2^ |= first & bit
			} else {
				child1^ |= first & bit
				child2^ |= second & bit
			}
		}
	} else {
		for gene := 0; gene < n_var; gene += 1 {
			bit := u64(1) << u64(gene)
			if bounded(state, 2) == 1 {
				child1^ |= first & bit
				child2^ |= second & bit
			} else {
				child1^ |= second & bit
				child2^ |= first & bit
			}
		}
	}
}

@(export)
binary_genetic_algorithm :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 5 do return -1
	seed_value, n_var_value, n_pop_value, max_it_value := input[0], input[1], input[2], input[3]
	if length != 4 || seed_value < 0 || n_var_value < 2 || n_var_value > 32 ||
		n_pop_value < 2 || n_pop_value > 16 || n_pop_value % 2 != 0 ||
		max_it_value < 1 || max_it_value > 32 do return -1
	n_var, n_pop, max_it := int(n_var_value), int(n_pop_value), int(max_it_value)
	state := u64(seed_value)
	population: [MAX_POPULATION]u64 = {}
	best_cost := i64(n_var + 1)

	for member := 0; member < n_pop; member += 1 {
		candidate := u64(0)
		for gene := 0; gene < n_var; gene += 1 { candidate |= bounded(&state, 2) << u64(gene) }
		population[member] = candidate
		cost := cost_of(candidate, n_var)
		if cost < best_cost do best_cost = cost
	}

	for iteration := 0; iteration < max_it; iteration += 1 {
		costs: [MAX_POPULATION]i64 = {}
		total_cost := i64(0)
		for member := 0; member < n_pop; member += 1 {
			costs[member] = cost_of(population[member], n_var)
			total_cost += costs[member]
		}
		average := f64(total_cost) / f64(n_pop)
		probabilities: [MAX_POPULATION]f64 = {}
		probability_total := 0.0
		for member := 0; member < n_pop; member += 1 {
			scaled := f64(costs[member])
			if average != 0.0 do scaled /= average
			probabilities[member] = math.exp(-scaled)
			probability_total += probabilities[member]
		}

		pairs := n_pop / 2
		first_children: [MAX_POPULATION / 2]u64 = {}
		second_children: [MAX_POPULATION / 2]u64 = {}
		for pair := 0; pair < pairs; pair += 1 {
			first_index := select_parent(&probabilities[0], n_pop, probability_total, &state)
			second_index := select_parent(&probabilities[0], n_pop, probability_total, &state)
			crossover(population[first_index], population[second_index], n_var, &state,
				&first_children[pair], &second_children[pair])
		}

		offspring: [MAX_POPULATION]u64 = {}
		for pair := 0; pair < pairs; pair += 1 {
			offspring[pair] = first_children[pair]
			offspring[pairs + pair] = second_children[pair]
		}
		for member := 0; member < n_pop; member += 1 {
			for gene := 0; gene < n_var; gene += 1 {
				if unit_random(&state) < 0.02 do offspring[member] ^= u64(1) << u64(gene)
			}
			cost := cost_of(offspring[member], n_var)
			if cost < best_cost do best_cost = cost
		}

		merged: [MAX_POPULATION * 2]u64 = {}
		merged_count := 0
		for member := 0; member < n_pop; member += 1 { merged[merged_count] = population[member]; merged_count += 1 }
		for member := 0; member < n_pop; member += 1 { merged[merged_count] = offspring[member]; merged_count += 1 }
		for index := 1; index < merged_count; index += 1 {
			selected := merged[index]
			selected_cost := cost_of(selected, n_var)
			insertion := index
			for insertion > 0 && cost_of(merged[insertion - 1], n_var) > selected_cost {
				merged[insertion] = merged[insertion - 1]
				insertion -= 1
			}
			merged[insertion] = selected
		}
		for member := 0; member < n_pop; member += 1 { population[member] = merged[member] }
	}
	return best_cost
}
