package housing_top_trading_cycles

import "core:c"

MAX_N :: 8
MAX_INPUT_LENGTH :: 66

@(export)
housing_top_trading_cycles :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N do return -1
	n := int(n_value)
	if length != c.size_t(1 + n*n) do return -1

	var preferences: [MAX_N * MAX_N]int
	cursor := 1
	for agent := 0; agent < n; agent += 1 {
		var seen: [MAX_N]bool
		for rank := 0; rank < n; rank += 1 {
			house_value := input[cursor]
			cursor += 1
			if house_value < 0 || house_value >= n_value do return -1
			house := int(house_value)
			if seen[house] do return -1
			seen[house] = true
			preferences[agent*n+rank] = house
		}
	}

	var agent_active: [MAX_N]bool
	var house_active: [MAX_N]bool
	var allocation: [MAX_N]int
	for index := 0; index < n; index += 1 {
		agent_active[index] = true
		house_active[index] = true
	}
	active_count := n
	for active_count > 0 {
		var choice: [MAX_N]int
		for agent := 0; agent < n; agent += 1 {
			if !agent_active[agent] do continue
			choice[agent] = -1
			for rank := 0; rank < n; rank += 1 {
				house := preferences[agent*n+rank]
				if house_active[house] {
					choice[agent] = house
					break
				}
			}
			if choice[agent] < 0 do return -1
		}

		// Contract each agent -> chosen house -> owner pair into one agent edge.
		var next_agent: [MAX_N]int
		for agent := 0; agent < n; agent += 1 {
			if agent_active[agent] do next_agent[agent] = choice[agent]
		}
		var state: [MAX_N]int
		var path_position: [MAX_N]int
		for agent := 0; agent < n; agent += 1 do path_position[agent] = -1
		var selected_this_round: [MAX_N]bool
		var path: [MAX_N]int
		for start := 0; start < n; start += 1 {
			if !agent_active[start] || state[start] != 0 do continue
			current := start
			path_length := 0
			for state[current] == 0 {
				state[current] = 1
				path_position[current] = path_length
				path[path_length] = current
				path_length += 1
				current = next_agent[current]
			}
			if state[current] == 1 {
				cycle_start := path_position[current]
				for index := cycle_start; index < path_length; index += 1 {
					selected_this_round[path[index]] = true
				}
			}
			for index := 0; index < path_length; index += 1 {
				state[path[index]] = 2
				path_position[path[index]] = -1
			}
		}

		removed := 0
		for agent := 0; agent < n; agent += 1 {
			if selected_this_round[agent] {
				allocation[agent] = choice[agent]
				agent_active[agent] = false
				house_active[choice[agent]] = false
				removed += 1
			}
		}
		if removed == 0 do return -1
		active_count -= removed
	}

	packed := i64(1)
	for agent := 0; agent < n; agent += 1 {
		packed += i64(allocation[agent]) << (3 * agent)
	}
	return packed
}
