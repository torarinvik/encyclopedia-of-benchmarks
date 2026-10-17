module predecessor_constrained_dfs

const max_nodes = 16
const max_input_values = 2 + max_nodes * max_nodes
const max_events = max_nodes + max_nodes * (max_nodes - 1) / 2

fn visit_node(node int, count int, adjacent &bool, predecessors &bool, visited &bool,
	events &i64, event_count &int, next_order &int) bool {
	unsafe {
		if *event_count >= max_events { return false }
		visited[node] = true
		index := 3 * *event_count
		events[index] = 1; events[index + 1] = i64(node); events[index + 2] = i64(*next_order)
		*event_count += 1
		*next_order += 1
		for child in 0 .. count {
			if !adjacent[node * max_nodes + child] || visited[child] { continue }
			mut all_visited := true
			for parent in 0 .. count {
				if predecessors[child * max_nodes + parent] && !visited[parent] { all_visited = false; break }
			}
			if all_visited {
				if !visit_node(child, count, adjacent, predecessors, visited, events, event_count, next_order) { return false }
			} else {
				if *event_count >= max_events { return false }
				index = 3 * *event_count
				events[index] = 0; events[index + 1] = i64(child); events[index + 2] = -1
				*event_count += 1
			}
		}
		return true
	}
}

fn write_i32_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 4 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 0xff) } }
}

@[export: 'predecessor_constrained_dfs']
pub fn predecessor_constrained_dfs(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_values) { return -1 }
		raw_count := input[0]; raw_start := input[1]
		if raw_count < 1 || raw_count > max_nodes || raw_start < 0 || raw_start >= raw_count { return -1 }
		count := int(raw_count)
		if int(length) != 2 + count * count { return -1 }
		mut adjacent := [max_nodes * max_nodes]bool{}
		mut predecessors := [max_nodes * max_nodes]bool{}
		mut indegree := [max_nodes]int{}
		for from in 0 .. count {
			for to in 0 .. count {
				bit := input[2 + from * count + to]
				if (bit != 0 && bit != 1) || (from == to && bit != 0) { return -1 }
				if bit == 1 {
					adjacent[from * max_nodes + to] = true
					predecessors[to * max_nodes + from] = true
					indegree[to]++
				}
			}
		}
		mut queue := [max_nodes]int{}
		mut head := 0; mut tail := 0
		for node in 0 .. count { if indegree[node] == 0 { queue[tail] = node; tail++ } }
		for head < tail {
			node := queue[head]; head++
			for child in 0 .. count {
				if adjacent[node * max_nodes + child] {
					indegree[child]--
					if indegree[child] == 0 { queue[tail] = child; tail++ }
				}
			}
		}
		if tail != count { return -1 }
		mut visited := [max_nodes]bool{}
		mut events := [max_events * 3]i64{}
		mut event_count := 0; mut next_order := 0
		if !visit_node(int(raw_start), count, &adjacent[0], &predecessors[0], &visited[0], &events[0], &event_count, &next_order) { return -1 }
		byte_count := 12 * event_count
		if output == nil || int(output_capacity) < byte_count { return -2 }
		for event in 0 .. event_count {
			index := 3 * event
			write_i32_le(mut output, 12 * event, events[index])
			write_i32_le(mut output, 12 * event + 4, events[index + 1])
			write_i32_le(mut output, 12 * event + 8, events[index + 2])
		}
		return i64(byte_count)
	}
}
