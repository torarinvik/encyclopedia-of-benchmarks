module binary_genetic_algorithm

import math

const max_population = 16
const max_u64 = u64(0xffffffffffffffff)

fn next_word(mut state &u64) u64 {
	unsafe {
		state[0] = state[0] +% u64(0x9E3779B97F4A7C15)
		mut value := state[0]
		value = (value ^ (value >> 30)) * u64(0xBF58476D1CE4E5B9)
		value = (value ^ (value >> 27)) * u64(0x94D049BB133111EB)
		return value ^ (value >> 31)
	}
}

fn bounded(mut state &u64, bound u64) u64 {
	threshold := ((max_u64 % bound) + 1) % bound
	for {
		value := next_word(mut state)
		if value >= threshold { return value % bound }
	}
}

fn unit_random(mut state &u64) f64 {
	return f64(next_word(mut state) >> 11) / 9007199254740992.0
}

fn cost_of(candidate u64, n_var int) i64 {
	mut cost := i64(0)
	for gene in 0 .. n_var {
		cost += i64((candidate >> u64(gene)) & 1)
	}
	return cost
}

fn select_parent(probabilities [max_population]f64, n_pop int, total f64, mut state &u64) int {
	target := unit_random(mut state) * total
	mut cumulative := 0.0
	for index in 0 .. n_pop {
		cumulative += probabilities[index]
		if target <= cumulative { return index }
	}
	return n_pop - 1
}

fn crossover(first u64, second u64, n_var int, mut state &u64, mut child1 &u64, mut child2 &u64) {
	unsafe {
		kind := bounded(mut state, 3)
		child1[0] = 0
		child2[0] = 0
		if kind == 0 {
			cut := int(bounded(mut state, u64(n_var - 1))) + 1
			for gene in 0 .. n_var {
				bit := u64(1) << u64(gene)
				if gene < cut {
					child1[0] |= first & bit
					child2[0] |= second & bit
				} else {
					child1[0] |= second & bit
					child2[0] |= first & bit
				}
			}
		} else if kind == 1 {
			mut low := int(bounded(mut state, u64(n_var))) + 1
			mut high := int(bounded(mut state, u64(n_var - 1))) + 1
			if high >= low { high++ }
			if high < low {
				temporary := low
				low = high
				high = temporary
			}
			for gene in 0 .. n_var {
				bit := u64(1) << u64(gene)
				exchange := gene >= low && gene < high
				if exchange {
					child1[0] |= second & bit
					child2[0] |= first & bit
				} else {
					child1[0] |= first & bit
					child2[0] |= second & bit
				}
			}
		} else {
			for gene in 0 .. n_var {
				bit := u64(1) << u64(gene)
				if bounded(mut state, 2) == 1 {
					child1[0] |= first & bit
					child2[0] |= second & bit
				} else {
					child1[0] |= second & bit
					child2[0] |= first & bit
				}
			}
		}
	}
}

@[export: 'binary_genetic_algorithm']
pub fn binary_genetic_algorithm(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 5 { return -1 }
		seed_value := input[0]
		n_var_value := input[1]
		n_pop_value := input[2]
		max_it_value := input[3]
		if length != 4 || seed_value < 0 || n_var_value < 2 || n_var_value > 32 ||
			n_pop_value < 2 || n_pop_value > 16 || n_pop_value % 2 != 0 ||
			max_it_value < 1 || max_it_value > 32 {
			return -1
		}
		n_var := int(n_var_value)
		n_pop := int(n_pop_value)
		max_it := int(max_it_value)
		mut state := u64(seed_value)
		mut population := [max_population]u64{}
		mut best_cost := i64(n_var + 1)

		for member in 0 .. n_pop {
			mut candidate := u64(0)
			for gene in 0 .. n_var {
				candidate |= bounded(mut state, 2) << u64(gene)
			}
			population[member] = candidate
			cost := cost_of(candidate, n_var)
			if cost < best_cost { best_cost = cost }
		}

		for _ in 0 .. max_it {
			mut costs := [max_population]i64{}
			mut total_cost := i64(0)
			for member in 0 .. n_pop {
				costs[member] = cost_of(population[member], n_var)
				total_cost += costs[member]
			}
			average := f64(total_cost) / f64(n_pop)
			mut probabilities := [max_population]f64{}
			mut probability_total := 0.0
			for member in 0 .. n_pop {
				scaled := if average != 0.0 { f64(costs[member]) / average } else { f64(costs[member]) }
				probabilities[member] = math.exp(-scaled)
				probability_total += probabilities[member]
			}

			pairs := n_pop / 2
			mut first_children := [max_population / 2]u64{}
			mut second_children := [max_population / 2]u64{}
			for pair in 0 .. pairs {
				first_index := select_parent(probabilities, n_pop, probability_total, mut state)
				second_index := select_parent(probabilities, n_pop, probability_total, mut state)
				mut child1 := u64(0)
				mut child2 := u64(0)
				crossover(population[first_index], population[second_index], n_var, mut state,
					mut child1, mut child2)
				first_children[pair] = child1
				second_children[pair] = child2
			}

			mut offspring := [max_population]u64{}
			for pair in 0 .. pairs {
				offspring[pair] = first_children[pair]
				offspring[pairs + pair] = second_children[pair]
			}
			for member in 0 .. n_pop {
				for gene in 0 .. n_var {
					if unit_random(mut state) < 0.02 { offspring[member] ^= u64(1) << u64(gene) }
				}
				cost := cost_of(offspring[member], n_var)
				if cost < best_cost { best_cost = cost }
			}

			mut merged := [max_population * 2]u64{}
			mut merged_count := 0
			for member in 0 .. n_pop {
				merged[merged_count] = population[member]
				merged_count++
			}
			for member in 0 .. n_pop {
				merged[merged_count] = offspring[member]
				merged_count++
			}
			for index in 1 .. merged_count {
				selected := merged[index]
				selected_cost := cost_of(selected, n_var)
				mut insertion := index
				for insertion > 0 && cost_of(merged[insertion - 1], n_var) > selected_cost {
					merged[insertion] = merged[insertion - 1]
					insertion--
				}
				merged[insertion] = selected
			}
			for member in 0 .. n_pop { population[member] = merged[member] }
		}
		return best_cost
	}
}
