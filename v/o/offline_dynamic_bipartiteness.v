module offline_dynamic_bipartiteness

const max_vertices = 16
const max_events = 64
const max_input_values = 2 + 4 * max_events + 1
const tree_nodes = 4 * max_events + 8

fn add_interval(node int, left int, right int, query_left int, query_right int,
	edge_id int, mut bucket_count []int, mut buckets []int) {
	if query_left <= left && right <= query_right {
		buckets[node * max_events + bucket_count[node]] = edge_id
		bucket_count[node]++
		return
	}
	middle := left + (right - left) / 2
	if query_left < middle {
		add_interval(node * 2, left, middle, query_left, query_right, edge_id,
			mut bucket_count, mut buckets)
	}
	if query_right > middle {
		add_interval(node * 2 + 1, middle, right, query_left, query_right, edge_id,
			mut bucket_count, mut buckets)
	}
}

fn constrain_opposite(left int, right int, mut parent []int, mut set_size []int,
	mut xor_parent []int, mut history_kind []int, mut history_child []int,
	mut history_root []int, mut history_size []int, mut history_xor []int,
	mut history_count int, mut contradictions int) {
	mut root_left := left
	mut root_right := right
	mut parity_left := 0
	mut parity_right := 0
	for parent[root_left] != root_left {
		parity_left ^= xor_parent[root_left]
		root_left = parent[root_left]
	}
	for parent[root_right] != root_right {
		parity_right ^= xor_parent[root_right]
		root_right = parent[root_right]
	}
	if root_left == root_right {
		if parity_left ^ parity_right != 1 {
			history_kind[history_count] = 1
			history_count++
			contradictions++
		}
		return
	}
	if set_size[root_left] > set_size[root_right] {
		root_left, root_right = root_right, root_left
	}
	history_kind[history_count] = 0
	history_child[history_count] = root_left
	history_root[history_count] = root_right
	history_size[history_count] = set_size[root_right]
	history_xor[history_count] = xor_parent[root_left]
	history_count++
	parent[root_left] = root_right
	xor_parent[root_left] = parity_left ^ parity_right ^ 1
	set_size[root_right] += set_size[root_left]
}

fn rollback_to(checkpoint int, mut parent []int, mut set_size []int,
	mut xor_parent []int, history_kind []int, history_child []int,
	history_root []int, history_size []int, history_xor []int,
	mut history_count int, mut contradictions int) {
	for history_count > checkpoint {
		history_count--
		entry := history_count
		if history_kind[entry] == 1 {
			contradictions--
		} else {
			child := history_child[entry]
			root := history_root[entry]
			parent[child] = child
			xor_parent[child] = history_xor[entry]
			set_size[root] = history_size[entry]
		}
	}
}

fn solve_time_tree(node int, left int, right int, operation []i64,
	edge_left []i64, edge_right []i64, bucket_count []int, buckets []int,
	mut parent []int, mut set_size []int, mut xor_parent []int,
	mut history_kind []int, mut history_child []int, mut history_root []int,
	mut history_size []int, mut history_xor []int, mut history_count int,
	mut contradictions int, mut answer []i64) {
	checkpoint := history_count
	for entry in 0 .. bucket_count[node] {
		edge_id := buckets[node * max_events + entry]
		constrain_opposite(int(edge_left[edge_id]), int(edge_right[edge_id]),
			mut parent, mut set_size, mut xor_parent, mut history_kind,
			mut history_child, mut history_root, mut history_size, mut history_xor,
			mut history_count, mut contradictions)
	}
	if right - left == 1 {
		if operation[left] == 2 {
			answer[left] = if contradictions == 0 { 1 } else { 0 }
		}
	} else {
		middle := left + (right - left) / 2
		solve_time_tree(node * 2, left, middle, operation, edge_left, edge_right,
			bucket_count, buckets, mut parent, mut set_size, mut xor_parent,
			mut history_kind, mut history_child, mut history_root, mut history_size,
			mut history_xor, mut history_count, mut contradictions, mut answer)
		solve_time_tree(node * 2 + 1, middle, right, operation, edge_left, edge_right,
			bucket_count, buckets, mut parent, mut set_size, mut xor_parent,
			mut history_kind, mut history_child, mut history_root, mut history_size,
			mut history_xor, mut history_count, mut contradictions, mut answer)
	}
	rollback_to(checkpoint, mut parent, mut set_size, mut xor_parent,
		history_kind, history_child, history_root, history_size, history_xor,
		mut history_count, mut contradictions)
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'offline_dynamic_bipartiteness']
pub fn offline_dynamic_bipartiteness(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values {
		return -1
	}
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_vertices || q_value < 0 || q_value > max_events {
		return -1
	}
	vertex_count := int(n_value)
	event_count := int(q_value)
	if length != usize(2 + 4 * event_count) {
		return -1
	}

	mut operation := []i64{len: max_events}
	mut first := []i64{len: max_events}
	mut second := []i64{len: max_events}
	mut edge_left := []i64{len: max_events}
	mut edge_right := []i64{len: max_events}
	mut start_time := []int{len: max_events}
	mut used_id := []bool{len: max_events}
	mut active := []bool{len: max_events}
	mut query_count := 0
	for time in 0 .. event_count {
		offset := 2 + 4 * time
		operation[time] = unsafe { input[offset] }
		first[time] = unsafe { input[offset + 1] }
		second[time] = unsafe { input[offset + 2] }
		third := unsafe { input[offset + 3] }
		if operation[time] == 0 {
			edge_id := first[time]
			if edge_id < 0 || edge_id >= max_events || second[time] < 0 ||
				second[time] > third || third >= n_value || used_id[int(edge_id)] {
				return -1
			}
			for prior in 0 .. max_events {
				if active[prior] && edge_left[prior] == second[time] && edge_right[prior] == third {
					return -1
				}
			}
			used_id[int(edge_id)] = true
			active[int(edge_id)] = true
			start_time[int(edge_id)] = time
			edge_left[int(edge_id)] = second[time]
			edge_right[int(edge_id)] = third
		} else if operation[time] == 1 {
			edge_id := first[time]
			if edge_id < 0 || edge_id >= max_events || !active[int(edge_id)] ||
				second[time] != 0 || third != 0 {
				return -1
			}
			active[int(edge_id)] = false
		} else if operation[time] == 2 {
			if first[time] != 0 || second[time] != 0 || third != 0 {
				return -1
			}
			query_count++
		} else {
			return -1
		}
	}

	required := 8 * query_count
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	mut bucket_count := []int{len: tree_nodes}
	mut buckets := []int{len: tree_nodes * max_events}
	for edge_id in 0 .. max_events {
		if !used_id[edge_id] {
			continue
		}
		mut end_time := event_count
		if !active[edge_id] {
			for time in start_time[edge_id] + 1 .. event_count {
				if operation[time] == 1 && first[time] == i64(edge_id) {
					end_time = time
					break
				}
			}
		}
		if start_time[edge_id] < end_time && event_count != 0 {
			add_interval(1, 0, event_count, start_time[edge_id], end_time,
				edge_id, mut bucket_count, mut buckets)
		}
	}

	mut parent := []int{len: max_vertices}
	mut set_size := []int{len: max_vertices, init: 1}
	mut xor_parent := []int{len: max_vertices}
	for vertex in 0 .. vertex_count {
		parent[vertex] = vertex
	}
	mut history_kind := []int{len: max_events}
	mut history_child := []int{len: max_events}
	mut history_root := []int{len: max_events}
	mut history_size := []int{len: max_events}
	mut history_xor := []int{len: max_events}
	mut history_count := 0
	mut contradictions := 0
	mut answer := []i64{len: max_events}
	if event_count != 0 {
		solve_time_tree(1, 0, event_count, operation, edge_left, edge_right,
			bucket_count, buckets, mut parent, mut set_size, mut xor_parent,
			mut history_kind, mut history_child, mut history_root, mut history_size,
			mut history_xor, mut history_count, mut contradictions, mut answer)
	}
	mut written := 0
	for time in 0 .. event_count {
		if operation[time] == 2 {
			store_i64_le(mut output, written, answer[time])
			written += 8
		}
	}
	return i64(written)
}
