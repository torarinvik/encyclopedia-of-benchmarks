package nni_phylogeny_distance

import "core:c"

MAX_LEAVES :: 7
MAX_EDGES :: 11
MAX_INPUT :: 23
MAX_STATES :: 945
MAX_DEGREE :: 8

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
}

bit_count :: proc(value: u16, n: int) -> int {
	count := 0
	for bit := 0; bit < n; bit += 1 { count += int((value >> u16(bit)) & 1) }
	return count
}

valid_tree :: proc(input: [^]i64, offset, n, edges: int) -> bool {
	splits: [MAX_EDGES]u16
	internal: [MAX_EDGES]u16
	internal_count := 0
	universe := u16((1 << u16(n)) - 1)
	for edge := 0; edge < edges; edge += 1 {
		raw := input[offset + edge]
		if raw <= 0 || u64(raw) >= u64(universe) || (raw & 1) != 0 do return false
		splits[edge] = u16(raw)
		for earlier := 0; earlier < edge; earlier += 1 { if splits[earlier] == splits[edge] do return false }
		size := bit_count(splits[edge], n)
		if size == 1 || size == n - 1 {
			if size == n - 1 && splits[edge] != (universe ^ 1) do return false
		} else if size >= 2 && size <= n - 2 {
			internal[internal_count] = splits[edge]
			internal_count += 1
		} else {
			return false
		}
	}
	if internal_count != n - 3 do return false
	for leaf := 1; leaf < n; leaf += 1 {
		pendant := u16(1) << u16(leaf)
		found := 0
		for edge := 0; edge < edges; edge += 1 { if splits[edge] == pendant do found += 1 }
		if found != 1 do return false
	}
	root_pendant := 0
	for edge := 0; edge < edges; edge += 1 { if splits[edge] == (universe ^ 1) do root_pendant += 1 }
	if root_pendant != 1 do return false
	for i := 0; i < internal_count; i += 1 {
		for j := i + 1; j < internal_count; j += 1 {
			common := internal[i] & internal[j]
			if common != 0 && common != internal[i] && common != internal[j] do return false
		}
	}
	return true
}

sort_state :: proc(state: [^]u16, count: int) {
	for i := 1; i < count; i += 1 {
		value := state[i]
		j := i
		for j > 0 && state[j-1] > value { state[j] = state[j-1]; j -= 1 }
		state[j] = value
	}
}

same_state :: proc(left: [^]u16, left_offset: int, right: [^]u16, right_offset: int, edges: int) -> bool {
	for i := 0; i < edges; i += 1 { if left[left_offset+i] != right[right_offset+i] do return false }
	return true
}

enumerate_states :: proc(leaves: int, a, b: [^]u16, state_count: ^int) -> [^]u16 {
	current := a
	next := b
	current[0] = 2; current[1] = 4; current[2] = 6
	state_count^ = 1
	old_edges := 3
	for size := 4; size <= leaves; size += 1 {
		new_edges := old_edges + 2
		new_bit := u16(1) << u16(size - 1)
		next_count := 0
		for state_index := 0; state_index < state_count^; state_index += 1 {
			old_offset := state_index * MAX_EDGES
			for selected_index := 0; selected_index < old_edges; selected_index += 1 {
				selected := current[old_offset + selected_index]
				candidate: [MAX_EDGES]u16
				candidate_count := 0
				for edge := 0; edge < old_edges; edge += 1 {
					split := current[old_offset + edge]
					if split == selected {
						candidate[candidate_count] = split; candidate_count += 1
						candidate[candidate_count] = split | new_bit; candidate_count += 1
					} else if (selected & split) == selected {
						candidate[candidate_count] = split | new_bit; candidate_count += 1
					} else {
						candidate[candidate_count] = split; candidate_count += 1
					}
				}
				candidate[candidate_count] = new_bit; candidate_count += 1
				sort_state(&candidate[0], candidate_count)
				found := 0
				for found < next_count && !same_state(next, found*MAX_EDGES, &candidate[0], 0, new_edges) { found += 1 }
				if found == next_count {
					if next_count >= MAX_STATES do return nil
					for edge := 0; edge < new_edges; edge += 1 { next[next_count*MAX_EDGES+edge] = candidate[edge] }
					next_count += 1
				}
			}
		}
		temp := current; current = next; next = temp
		state_count^ = next_count
		old_edges = new_edges
	}
	return current
}

@(export)
nni_phylogeny_distance :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 7 || length > MAX_INPUT do return -1
	if input[0] < 3 || input[0] > MAX_LEAVES do return -1
	leaves := int(input[0])
	edges := 2 * leaves - 3
	if length != c.size_t(1+2*edges) || !valid_tree(input, 1, leaves, edges) || !valid_tree(input, 1+edges, leaves, edges) do return -1
	states_a: [MAX_STATES * MAX_EDGES]u16
	states_b: [MAX_STATES * MAX_EDGES]u16
	state_count := 0
	states := enumerate_states(leaves, &states_a[0], &states_b[0], &state_count)
	if states == nil do return -1
	start: [MAX_EDGES]u16
	goal: [MAX_EDGES]u16
	for i := 0; i < edges; i += 1 { start[i] = u16(input[1+i]); goal[i] = u16(input[1+edges+i]) }
	sort_state(&start[0], edges); sort_state(&goal[0], edges)
	start_index, goal_index := state_count, state_count
	for i := 0; i < state_count; i += 1 {
		if same_state(states, i*MAX_EDGES, &start[0], 0, edges) { start_index = i }
		if same_state(states, i*MAX_EDGES, &goal[0], 0, edges) { goal_index = i }
	}
	if start_index == state_count || goal_index == state_count do return -1
	neighbors: [MAX_STATES * MAX_DEGREE]u16
	degree: [MAX_STATES]u8
	for left := 0; left < state_count; left += 1 {
		for right := left+1; right < state_count; right += 1 {
			common := 0
			for i := 0; i < edges; i += 1 {
				left_size := bit_count(states[left*MAX_EDGES+i], leaves)
				if left_size < 2 || left_size > leaves-2 do continue
				for j := 0; j < edges; j += 1 {
					right_split := states[right*MAX_EDGES+j]
					right_size := bit_count(right_split, leaves)
					if right_size >= 2 && right_size <= leaves-2 && states[left*MAX_EDGES+i] == right_split { common += 1; break }
				}
			}
			if common+leaves == edges-1 {
				if degree[left] >= MAX_DEGREE || degree[right] >= MAX_DEGREE do return -1
				neighbors[left*MAX_DEGREE+int(degree[left])] = u16(right); degree[left] += 1
				neighbors[right*MAX_DEGREE+int(degree[right])] = u16(left); degree[right] += 1
			}
		}
	}
	distance: [MAX_STATES]i16
	queue: [MAX_STATES]u16
	for i := 0; i < state_count; i += 1 { distance[i] = -1 }
	head, tail := 0, 0
	distance[start_index] = 0; queue[tail] = u16(start_index); tail += 1
	for head < tail {
		current := int(queue[head]); head += 1
		if current == goal_index do break
		for i := 0; i < int(degree[current]); i += 1 {
			next := int(neighbors[current*MAX_DEGREE+i])
			if distance[next] < 0 { distance[next] = distance[current]+1; queue[tail] = u16(next); tail += 1 }
		}
	}
	if distance[goal_index] < 0 do return -1
	if output == nil || capacity < 8 do return -2
	staged: [8]u8
	store_i64_le(&staged[0], i64(distance[goal_index]))
	for byte := 0; byte < 8; byte += 1 { output[byte] = staged[byte] }
	return 8
}
