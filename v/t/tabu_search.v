const max_cities = 6
const max_tour = 7
const max_candidates = 32
const max_output_bytes = 36

fn store_i32_le(mut output &u8, offset int, value i64) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn route_cost(route [max_tour]i64, route_length int, edge_cost [max_cities * max_cities]i64) i64 {
	mut cost := i64(0)
	for i in 0 .. route_length - 1 {
		cost += edge_cost[int(route[i]) * max_cities + int(route[i + 1])]
	}
	return cost
}

@[export: 'tabu_search']
pub fn tabu_search(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 19 { return -1 }
		if input[0] < 4 || input[0] > 6 || input[1] < 0 || input[1] > 8 || input[2] < 1 || input[2] > 3 { return -1 }
		cities := int(input[0])
		iterations := int(input[1])
		tabu_size := int(input[2])
		edge_count := cities * (cities - 1) / 2
		if input_length != usize(3 + edge_count) { return -1 }
		mut edge_cost := [max_cities * max_cities]i64{}
		mut offset := 3
		for left in 0 .. cities {
			for right in left + 1 .. cities {
				weight := input[offset]
				if weight < 1 || weight > 99 { return -1 }
				edge_cost[left * max_cities + right] = weight
				edge_cost[right * max_cities + left] = weight
				offset++
			}
		}
		mut solution := [max_tour]i64{}
		mut solution_length := 0
		mut visited := [max_cities]bool{}
		mut current := 0
		for !visited[current] {
			mut minimum := i64(10000)
			mut best_node := current
			for node in 0 .. cities {
				if node != current && !visited[node] {
					weight := edge_cost[current * max_cities + node]
					if weight < minimum { minimum = weight; best_node = node }
				}
			}
			visited[current] = true
			solution[solution_length] = i64(current)
			solution_length++
			current = best_node
		}
		solution[solution_length] = 0
		solution_length++
		mut best_solution := solution
		mut best_cost := route_cost(solution, solution_length, edge_cost)

		mut tabu := [3][2]i64{}
		mut tabu_count := 0
		for _ in 0 .. iterations {
			mut candidates := [max_candidates][max_tour]i64{}
			mut candidate_costs := [max_candidates]i64{}
			mut candidate_count := 0
			for first in 1 .. solution_length - 1 {
				for second in 1 .. solution_length - 1 {
					if first == second { continue }
					mut candidate := solution
					temporary := candidate[first]
					candidate[first] = candidate[second]
					candidate[second] = temporary
					mut duplicate := false
					for prior in 0 .. candidate_count {
						mut same := true
						for i in 0 .. solution_length {
							if candidates[prior][i] != candidate[i] { same = false }
						}
						if same { duplicate = true }
					}
					if !duplicate {
						candidates[candidate_count] = candidate
						candidate_costs[candidate_count] = route_cost(candidate, solution_length, edge_cost)
						candidate_count++
					}
				}
			}
			// Stable insertion sort by candidate cost.
			for i in 1 .. candidate_count {
				mut j := i
				for j > 0 && candidate_costs[j] < candidate_costs[j - 1] {
					tmp_cost := candidate_costs[j]
					candidate_costs[j] = candidate_costs[j - 1]
					candidate_costs[j - 1] = tmp_cost
					tmp_route := candidates[j]
					candidates[j] = candidates[j - 1]
					candidates[j - 1] = tmp_route
					j--
				}
			}
			for selected in 0 .. candidate_count {
				mut difference := -1
				for i in 0 .. solution_length {
					if candidates[selected][i] != solution[i] { difference = i; break }
				}
				if difference < 0 { continue }
				new_city := candidates[selected][difference]
				old_city := solution[difference]
				mut is_tabu := false
				for i in 0 .. tabu_count {
					if (tabu[i][0] == new_city && tabu[i][1] == old_city) || (tabu[i][0] == old_city && tabu[i][1] == new_city) { is_tabu = true }
				}
				if is_tabu { continue }
				tabu[tabu_count] = [2]i64{new_city, old_city}
				tabu_count++
				if tabu_count >= tabu_size {
					for i in 0 .. tabu_count - 1 { tabu[i] = tabu[i + 1] }
					tabu_count--
				}
				solution = candidates[selected]
				if candidate_costs[selected] < best_cost {
					best_cost = candidate_costs[selected]
					best_solution = solution
				}
				break
			}
		}
		mut staged := [max_output_bytes]u8{}
		store_i32_le(mut staged[0], 0, i64(solution_length))
		for i in 0 .. solution_length { store_i32_le(mut staged[0], 4 * (i + 1), best_solution[i]) }
		store_i32_le(mut staged[0], 4 * (solution_length + 1), best_cost)
		output_bytes := (solution_length + 2) * 4
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for i in 0 .. output_bytes { output[i] = staged[i] }
		return i64(output_bytes)
	}
}
