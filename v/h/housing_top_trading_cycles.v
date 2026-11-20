module housing_top_trading_cycles

const max_n = 8
const max_input_length = 66

@[export: 'housing_top_trading_cycles']
pub fn housing_top_trading_cycles(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if int(length) != 1 + n * n { return -1 }

		mut preferences := [max_n][max_n]int{}
		mut cursor := 1
		for agent in 0 .. n {
			mut seen := [max_n]bool{}
			for rank in 0 .. n {
				house_value := input[cursor]
				cursor++
				if house_value < 0 || house_value >= n_value { return -1 }
				house := int(house_value)
				if seen[house] { return -1 }
				seen[house] = true
				preferences[agent][rank] = house
			}
		}

		mut agent_active := [max_n]bool{}
		mut house_active := [max_n]bool{}
		mut allocation := [max_n]int{}
		for index in 0 .. n {
			agent_active[index] = true
			house_active[index] = true
		}
		mut active_count := n
		for active_count > 0 {
			mut choice := [max_n]int{}
			for agent in 0 .. n {
				if !agent_active[agent] { continue }
				choice[agent] = -1
				for rank in 0 .. n {
					house := preferences[agent][rank]
					if house_active[house] {
						choice[agent] = house
						break
					}
				}
				if choice[agent] < 0 { return -1 }
			}

			// Contract each agent -> chosen house -> owner pair into one agent edge.
			mut state := [max_n]int{}
			mut path_position := [max_n]int{init: -1}
			mut selected_this_round := [max_n]bool{}
			mut path := [max_n]int{}
			for start in 0 .. n {
				if !agent_active[start] || state[start] != 0 { continue }
				mut current := start
				mut path_length := 0
				for state[current] == 0 {
					state[current] = 1
					path_position[current] = path_length
					path[path_length] = current
					path_length++
					current = choice[current]
				}
				if state[current] == 1 {
					cycle_start := path_position[current]
					for index in cycle_start .. path_length {
						selected_this_round[path[index]] = true
					}
				}
				for index in 0 .. path_length {
					state[path[index]] = 2
					path_position[path[index]] = -1
				}
			}

			mut removed := 0
			for agent in 0 .. n {
				if selected_this_round[agent] {
					allocation[agent] = choice[agent]
					agent_active[agent] = false
					house_active[choice[agent]] = false
					removed++
				}
			}
			if removed == 0 { return -1 }
			active_count -= removed
		}

		mut packed := i64(1)
		for agent in 0 .. n {
			packed += i64(allocation[agent]) << (3 * agent)
		}
		return packed
	}
}
