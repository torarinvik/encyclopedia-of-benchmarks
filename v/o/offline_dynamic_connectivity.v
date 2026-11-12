module offline_dynamic_connectivity

const max_vertices = 16
const max_events = 32
const max_input_values = 2 + 4 * max_events + 1
const tree_nodes = 4 * max_events + 8

fn find_root(parent []int, vertex_input int) int {
	mut vertex := vertex_input
	for parent[vertex] != vertex {
		vertex = parent[vertex]
	}
	return vertex
}

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

fn unite(left int, right int, mut parent []int, mut set_size []int,
	mut history_child []int, mut history_root []int, mut history_size []int,
	mut history_count int) {
	mut root_left := find_root(parent, left)
	mut root_right := find_root(parent, right)
	if root_left == root_right {
		return
	}
	if set_size[root_left] > set_size[root_right] {
		root_left, root_right = root_right, root_left
	}
	history_child[history_count] = root_left
	history_root[history_count] = root_right
	history_size[history_count] = set_size[root_right]
	history_count++
	parent[root_left] = root_right
	set_size[root_right] += set_size[root_left]
}

fn rollback_to(checkpoint int, mut parent []int, mut set_size []int,
	history_child []int, history_root []int, history_size []int,
	mut history_count int) {
	for history_count > checkpoint {
		history_count--
		child := history_child[history_count]
		root := history_root[history_count]
		parent[child] = child
		set_size[root] = history_size[history_count]
	}
}

fn solve_time_tree(node int, left int, right int,
	operation []i64, first []i64, second []i64, edge_left []i64, edge_right []i64,
	bucket_count []int, buckets []int, mut parent []int, mut set_size []int,
	mut history_child []int, mut history_root []int, mut history_size []int,
	mut history_count int, mut answer []i64) {
	checkpoint := history_count
	for entry in 0 .. bucket_count[node] {
		edge_id := buckets[node * max_events + entry]
		unite(int(edge_left[edge_id]), int(edge_right[edge_id]), mut parent,
			mut set_size, mut history_child, mut history_root, mut history_size,
			mut history_count)
	}
	if right - left == 1 {
		if operation[left] == 2 {
			if find_root(parent, int(first[left])) == find_root(parent, int(second[left])) {
				answer[left] = 1
			} else {
				answer[left] = 0
			}
		}
	} else {
		middle := left + (right - left) / 2
		solve_time_tree(node * 2, left, middle, operation, first, second,
			edge_left, edge_right, bucket_count, buckets, mut parent, mut set_size,
			mut history_child, mut history_root, mut history_size, mut history_count,
			mut answer)
		solve_time_tree(node * 2 + 1, middle, right, operation, first, second,
			edge_left, edge_right, bucket_count, buckets, mut parent, mut set_size,
			mut history_child, mut history_root, mut history_size, mut history_count,
			mut answer)
	}
	rollback_to(checkpoint, mut parent, mut set_size, history_child, history_root,
		history_size, mut history_count)
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

@[export: 'offline_dynamic_connectivity']
pub fn offline_dynamic_connectivity(input &i64, length usize, mut output &u8, capacity usize) i64 {
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
				second[time] >= n_value || third < 0 || third >= n_value ||
				used_id[int(edge_id)] {
				return -1
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
			if first[time] < 0 || first[time] >= n_value || second[time] < 0 ||
				second[time] >= n_value || third != 0 {
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
	for vertex in 0 .. vertex_count {
		parent[vertex] = vertex
	}
	mut history_child := []int{len: max_vertices}
	mut history_root := []int{len: max_vertices}
	mut history_size := []int{len: max_vertices}
	mut history_count := 0
	mut answer := []i64{len: max_events}
	if event_count != 0 {
		solve_time_tree(1, 0, event_count, operation, first, second, edge_left,
			edge_right, bucket_count, buckets, mut parent, mut set_size,
			mut history_child, mut history_root, mut history_size,
			mut history_count, mut answer)
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
