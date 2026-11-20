@[export: 'lawler_knapsack_profit_scaling_fptas']
pub fn lawler_knapsack_profit_scaling_fptas(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 19 { return -1 }
		capacity := input[0]
		n64 := input[1]
		if capacity < 1 || capacity > 30 || n64 < 4 || n64 > 8 || length != usize(2 + 2 * n64) { return -1 }
		n := int(n64)
		mut weights := [8]i64{}
		mut profits := [8]i64{}
		mut order := [8]int{}
		mut maximum_profit := i64(0)
		for i in 0 .. n {
			weights[i] = input[2 + 2 * i]
			profits[i] = input[3 + 2 * i]
			if weights[i] < 1 || weights[i] > capacity || profits[i] < 32 || profits[i] > 200 { return -1 }
			order[i] = i
			if profits[i] > maximum_profit { maximum_profit = profits[i] }
		}

		// Stable insertion sort by exact descending profit/weight ratio.
		for i in 1 .. n {
			key := order[i]
			mut j := i
			for j > 0 && profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key] {
				order[j] = order[j - 1]
				j--
			}
			order[j] = key
		}

		mut prefix_mask := i64(0)
		mut prefix_profit := i64(0)
		mut used := i64(0)
		mut lower_bound := i64(0)
		mut exact := false
		for position in 0 .. n {
			item := order[position]
			if used + weights[item] > capacity {
				lower_bound = prefix_profit
				if maximum_profit > lower_bound { lower_bound = maximum_profit }
				break
			}
			used += weights[item]
			prefix_profit += profits[item]
			prefix_mask |= i64(1) << item
			if used == capacity || position + 1 == n {
				exact = true
				break
			}
		}
		if exact { return (prefix_profit << 8) | prefix_mask }

		mut small_order := [8]int{}
		mut small_count := 0
		mut group_count := [17]int{}
		mut group_items := [136]int{}
		for i in 0 .. n {
			if 4 * profits[i] <= lower_bound {
				small_order[small_count] = i
				small_count++
			} else {
				mut q := 0
				if 4 * profits[i] <= 2 * lower_bound { q = int(16 * profits[i] / lower_bound) }
				else { q = 2 * int(8 * profits[i] / lower_bound) }
				if q < 1 || q > 16 { return -1 }
				group_items[q * n + group_count[q]] = i
				group_count[q]++
			}
		}

		for i in 1 .. small_count {
			key := small_order[i]
			mut j := i
			for j > 0 && profits[key] * weights[small_order[j - 1]] > profits[small_order[j - 1]] * weights[key] {
				small_order[j] = small_order[j - 1]
				j--
			}
			small_order[j] = key
		}
		for q in 1 .. 17 {
			base := q * n
			for i in 1 .. group_count[q] {
				key := group_items[base + i]
				mut j := i
				for j > 0 {
					previous := group_items[base + j - 1]
					if weights[key] > weights[previous] || (weights[key] == weights[previous] && key > previous) { break }
					group_items[base + j] = previous
					j--
				}
				group_items[base + j] = key
			}
			limit := 32 / q
			if group_count[q] > limit { group_count[q] = limit }
		}

		// Keep the lightest state for each scaled large-profit total.
		mut state_weight := [33]i64{}
		mut state_mask := [33]i64{}
		mut state_profit := [33]i64{}
		for scaled in 0 .. 33 { state_weight[scaled] = capacity + 1 }
		state_weight[0] = 0
		mut group_step := 0
		for group_step < 16 {
			q := 16 - group_step
			group_step++
			count := group_count[q]
			if count == 0 { continue }
			mut next_weight := [33]i64{}
			mut next_mask := [33]i64{}
			mut next_profit := [33]i64{}
			for scaled in 0 .. 33 { next_weight[scaled] = capacity + 1 }
			for old_q in 0 .. 33 {
				if state_weight[old_q] > capacity { continue }
				if state_weight[old_q] < next_weight[old_q] || (state_weight[old_q] == next_weight[old_q] && (state_profit[old_q] > next_profit[old_q] || (state_profit[old_q] == next_profit[old_q] && state_mask[old_q] < next_mask[old_q]))) {
					next_weight[old_q] = state_weight[old_q]
					next_mask[old_q] = state_mask[old_q]
					next_profit[old_q] = state_profit[old_q]
				}
				mut group_weight := i64(0)
				mut group_mask := i64(0)
				mut group_profit := i64(0)
				for offset in 0 .. count {
					item := group_items[q * n + offset]
					new_group_weight := group_weight + weights[item]
					if state_weight[old_q] + new_group_weight > capacity { break }
					group_weight = new_group_weight
					group_mask |= i64(1) << item
					group_profit += profits[item]
					destination := old_q + q * (offset + 1)
					if destination > 32 { continue }
					new_weight := state_weight[old_q] + group_weight
					new_profit := state_profit[old_q] + group_profit
					new_mask := state_mask[old_q] | group_mask
					if new_weight < next_weight[destination] || (new_weight == next_weight[destination] && (new_profit > next_profit[destination] || (new_profit == next_profit[destination] && new_mask < next_mask[destination]))) {
						next_weight[destination] = new_weight
						next_mask[destination] = new_mask
						next_profit[destination] = new_profit
					}
				}
			}
			mut best_higher_weight := capacity + 1
			mut step := 0
			for step < 33 {
				scaled := 32 - step
				step++
				if next_weight[scaled] <= capacity && next_weight[scaled] < best_higher_weight {
					best_higher_weight = next_weight[scaled]
				} else {
					next_weight[scaled] = capacity + 1
					next_mask[scaled] = 0
					next_profit[scaled] = 0
				}
			}
			for scaled in 0 .. 33 {
				state_weight[scaled] = next_weight[scaled]
				state_mask[scaled] = next_mask[scaled]
				state_profit[scaled] = next_profit[scaled]
			}
		}

		mut best_score := i64(-1)
		mut best_profit := i64(-1)
		mut best_weight := capacity + 1
		mut best_mask := i64(0)
		for scaled in 0 .. 33 {
			if state_weight[scaled] > capacity { continue }
			mut remaining := capacity - state_weight[scaled]
			mut small_mask := i64(0)
			mut small_profit := i64(0)
			mut small_weight := i64(0)
			for position in 0 .. small_count {
				item := small_order[position]
				if weights[item] > remaining { break }
				remaining -= weights[item]
				small_weight += weights[item]
				small_profit += profits[item]
				small_mask |= i64(1) << item
			}
			score := lower_bound * i64(scaled) + 16 * small_profit
			total_profit := state_profit[scaled] + small_profit
			total_weight := state_weight[scaled] + small_weight
			mask := state_mask[scaled] | small_mask
			if score > best_score || (score == best_score && (total_profit > best_profit || (total_profit == best_profit && (total_weight < best_weight || (total_weight == best_weight && mask < best_mask))))) {
				best_score = score
				best_profit = total_profit
				best_weight = total_weight
				best_mask = mask
			}
		}
		return (best_profit << 8) | best_mask
	}
}
