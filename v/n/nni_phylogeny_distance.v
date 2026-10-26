module nni_phylogeny_distance

const max_leaves = 7
const max_edges = 11
const max_input = 23
const max_states = 945
const max_degree = 8

fn store_i64_le(mut output []u8, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[byte] = u8((bits >> (8 * byte)) & 255) }
}

fn bit_count(value u16, n int) int {
	mut count := 0
	for bit in 0 .. n { count += int((value >> bit) & 1) }
	return count
}

fn valid_tree(input &i64, offset int, n int, edges int) bool {
	mut splits := [max_edges]u16{init: 0}
	mut internal := [max_edges]u16{init: 0}
	mut internal_count := 0
	universe := (u16(1) << n) - 1
	unsafe {
		for edge in 0 .. edges {
			raw := input[offset + edge]
			if raw <= 0 || u64(raw) >= u64(universe) || (raw & 1) != 0 { return false }
			splits[edge] = u16(raw)
			for earlier in 0 .. edge { if splits[earlier] == splits[edge] { return false } }
			size := bit_count(splits[edge], n)
			if size == 1 || size == n - 1 {
				if size == n - 1 && splits[edge] != (universe ^ u16(1)) { return false }
			} else if size >= 2 && size <= n - 2 {
				internal[internal_count] = splits[edge]
				internal_count++
			} else { return false }
		}
		if internal_count != n - 3 { return false }
		for leaf in 1 .. n {
			pendant := u16(1) << leaf
			mut found := 0
			for edge in 0 .. edges { if splits[edge] == pendant { found++ } }
			if found != 1 { return false }
		}
		mut root_pendant := 0
		for edge in 0 .. edges { if splits[edge] == (universe ^ u16(1)) { root_pendant++ } }
		if root_pendant != 1 { return false }
		for i in 0 .. internal_count {
			for j in i + 1 .. internal_count {
				common := internal[i] & internal[j]
				if common != 0 && common != internal[i] && common != internal[j] { return false }
			}
		}
	}
	return true
}

fn sort_state(state &u16, count int) {
	unsafe {
		for i in 1 .. count {
			value := state[i]
			mut j := i
			for j > 0 && state[j - 1] > value { state[j] = state[j - 1]; j-- }
			state[j] = value
		}
	}
}

fn same_state(left &u16, left_offset int, right &u16, right_offset int, edges int) bool {
	unsafe {
		for i in 0 .. edges { if left[left_offset + i] != right[right_offset + i] { return false } }
	}
	return true
}

fn enumerate_states(leaves int, a &u16, b &u16, mut state_count &int) &u16 {
	mut current := a
	mut next := b
	unsafe {
		current[0] = 2; current[1] = 4; current[2] = 6
		state_count = 1
		mut old_edges := 3
		for size in 4 .. leaves + 1 {
			new_edges := old_edges + 2
			new_bit := u16(1) << (size - 1)
			mut next_count := 0
			for state_index in 0 .. state_count {
				old_offset := state_index * max_edges
				for selected_index in 0 .. old_edges {
					selected := current[old_offset + selected_index]
					mut candidate := [max_edges]u16{init: 0}
					mut candidate_count := 0
					for edge in 0 .. old_edges {
						split := current[old_offset + edge]
						if split == selected {
							candidate[candidate_count] = split; candidate_count++
							candidate[candidate_count] = split | new_bit; candidate_count++
						} else if (selected & split) == selected {
							candidate[candidate_count] = split | new_bit; candidate_count++
						} else {
							candidate[candidate_count] = split; candidate_count++
						}
					}
					candidate[candidate_count] = new_bit; candidate_count++
					sort_state(&candidate[0], candidate_count)
					mut found := 0
					for found < next_count && !same_state(next, found * max_edges, &candidate[0], 0, new_edges) { found++ }
					if found == next_count {
						if next_count >= max_states { return nil }
						for edge in 0 .. new_edges { next[next_count * max_edges + edge] = candidate[edge] }
						next_count++
					}
				}
			}
			temp := current; current = next; next = temp
			state_count = next_count
			old_edges = new_edges
		}
	}
	return current
}

@[export: 'nni_phylogeny_distance']
pub fn nni_phylogeny_distance(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 7 || length > max_input { return -1 }
		if input[0] < 3 || input[0] > max_leaves { return -1 }
		leaves := int(input[0])
		edges := 2 * leaves - 3
		if length != usize(1 + 2 * edges) || !valid_tree(input, 1, leaves, edges) || !valid_tree(input, 1 + edges, leaves, edges) { return -1 }
		mut states_a := [max_states * max_edges]u16{init: 0}
		mut states_b := [max_states * max_edges]u16{init: 0}
		mut state_count := 0
		states := enumerate_states(leaves, &states_a[0], &states_b[0], mut state_count)
		if states == nil { return -1 }
		mut start := [max_edges]u16{init: 0}
		mut goal := [max_edges]u16{init: 0}
		for i in 0 .. edges { start[i] = u16(input[1 + i]); goal[i] = u16(input[1 + edges + i]) }
		sort_state(&start[0], edges); sort_state(&goal[0], edges)
		mut start_index := state_count
		mut goal_index := state_count
		for i in 0 .. state_count {
			if same_state(states, i * max_edges, &start[0], 0, edges) { start_index = i }
			if same_state(states, i * max_edges, &goal[0], 0, edges) { goal_index = i }
		}
		if start_index == state_count || goal_index == state_count { return -1 }
		mut neighbors := [max_states * max_degree]u16{init: 0}
		mut degree := [max_states]u8{init: 0}
		for left in 0 .. state_count {
			for right in left + 1 .. state_count {
				mut common := 0
				for i in 0 .. edges {
					left_size := bit_count(states[left * max_edges + i], leaves)
					if left_size < 2 || left_size > leaves - 2 { continue }
					for j in 0 .. edges {
						right_split := states[right * max_edges + j]
						right_size := bit_count(right_split, leaves)
						if right_size >= 2 && right_size <= leaves - 2 && states[left * max_edges + i] == right_split { common++; break }
					}
				}
				if common + leaves == edges - 1 {
					if degree[left] >= max_degree || degree[right] >= max_degree { return -1 }
					neighbors[left * max_degree + int(degree[left])] = u16(right); degree[left]++
					neighbors[right * max_degree + int(degree[right])] = u16(left); degree[right]++
				}
			}
		}
		mut distance := [max_states]i16{init: 0}
		mut queue := [max_states]u16{init: 0}
		for i in 0 .. state_count { distance[i] = -1 }
		mut head := 0
		mut tail := 0
		distance[start_index] = 0; queue[tail] = u16(start_index); tail++
		for head < tail {
			current := int(queue[head]); head++
			if current == goal_index { break }
			for i in 0 .. int(degree[current]) {
				next := int(neighbors[current * max_degree + i])
				if distance[next] < 0 { distance[next] = distance[current] + 1; queue[tail] = u16(next); tail++ }
			}
		}
		if distance[goal_index] < 0 { return -1 }
		if output == nil || capacity < 8 { return -2 }
		mut staged := [8]u8{init: 0}
		store_i64_le(mut staged[..], i64(distance[goal_index]))
		for byte in 0 .. 8 { output[byte] = staged[byte] }
		return 8
	}
}
