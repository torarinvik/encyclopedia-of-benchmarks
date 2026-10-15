package astar_java_weighted_graph

import "core:c"

MAX_VERTICES :: 7
MAX_STATES :: 4096
Search_State :: struct {
	distance: i32,
	heuristic: i32,
	path_length: int,
	path: [MAX_VERTICES]i32,
}

write_i64 :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := u64(value)
	for byte_index := 0; byte_index < 8; byte_index += 1 {
		output[offset + usize(byte_index)] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
astar_java_weighted_graph :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 do return -1
	n64, m64, start64, target64 := input[0], input[1], input[2], input[3]
	if n64 < 1 || n64 > MAX_VERTICES || m64 < 0 || m64 > 16 ||
		start64 < 0 || start64 >= n64 || target64 < 0 || target64 >= n64 ||
		length != c.size_t(4 + n64 + 3 * m64) do return -1
	n, m, start, target := int(n64), int(m64), int(start64), int(target64)
	var heuristic: [MAX_VERTICES]i32
	var adjacent: [MAX_VERTICES][MAX_VERTICES]i32
	var weights: [MAX_VERTICES][MAX_VERTICES]i32
	var degree: [MAX_VERTICES]int
	for i := 0; i < n; i += 1 {
		if input[4 + i] < -1000 || input[4 + i] > 1000 do return -1
		heuristic[i] = i32(input[4 + i])
	}
	position := 4 + n
	for edge := 0; edge < m; edge += 1 {
		u64, v64, weight64 := input[position], input[position + 1], input[position + 2]
		position += 3
		if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 || weight64 < 0 || weight64 > 1000 do return -1
		u, v := int(u64), int(v64)
		for i := 0; i < degree[u]; i += 1 { if adjacent[u][i] == i32(v) do return -1 }
		adjacent[u][degree[u]] = i32(v); weights[u][degree[u]] = i32(weight64); degree[u] += 1
		adjacent[v][degree[v]] = i32(u); weights[v][degree[v]] = i32(weight64); degree[v] += 1
	}
	var states: [MAX_STATES]Search_State
	var heap: [MAX_STATES]int
	state_count, heap_size := 1, 1
	states[0].distance = 0
	states[0].heuristic = heuristic[start]
	states[0].path_length = 1
	states[0].path[0] = i32(start)
	heap[0] = 0
	found := false
	solution := 0
	for heap_size > 0 {
		current_index := heap[0]
		last := heap[heap_size - 1]
		heap_size -= 1
		if heap_size > 0 {
			i, half := 0, heap_size / 2
			for i < half {
				child := 2 * i + 1
				child_index := heap[child]
				right := child + 1
				if right < heap_size && states[heap[right]].distance + states[heap[right]].heuristic < states[child_index].distance + states[child_index].heuristic {
					child = right; child_index = heap[right]
				}
				if states[last].distance + states[last].heuristic <= states[child_index].distance + states[child_index].heuristic do break
				heap[i] = child_index; i = child
			}
			heap[i] = last
		}
		current := states[current_index]
		current_vertex := int(current.path[current.path_length - 1])
		if current_vertex == target { found = true; solution = current_index; break }
		for edge := 0; edge < degree[current_vertex]; edge += 1 {
			next := adjacent[current_vertex][edge]
			in_path := false
			for i := 0; i < current.path_length; i += 1 { if current.path[i] == next { in_path = true; break } }
			if in_path do continue
			if state_count >= MAX_STATES || heap_size >= MAX_STATES do return -1
			next_state := state_count
			state_count += 1
			states[next_state].distance = current.distance + weights[current_vertex][edge]
			states[next_state].heuristic = heuristic[int(next)]
			states[next_state].path_length = current.path_length + 1
			for i := 0; i < current.path_length; i += 1 { states[next_state].path[i] = current.path[i] }
			states[next_state].path[current.path_length] = next
			i := heap_size; heap_size += 1
			for i > 0 {
				parent := (i - 1) / 2
				parent_index := heap[parent]
				if states[parent_index].distance + states[parent_index].heuristic <= states[next_state].distance + states[next_state].heuristic do break
				heap[i] = parent_index; i = parent
			}
			heap[i] = next_state
		}
	}
	result: [10]i64
	result_words := 3
	if !found { result[0], result[1], result[2] = -1, -1, 0 }
	else {
		state := states[solution]
		result[0], result[1], result[2] = i64(state.distance), i64(state.heuristic), i64(state.path_length)
		result_words += state.path_length
		for i := 0; i < state.path_length; i += 1 { result[3 + i] = i64(state.path[i]) }
	}
	output_bytes := result_words * 8
	if output == nil || usize(capacity) < usize(output_bytes) do return -2
	for i := 0; i < result_words; i += 1 { write_i64(output, usize(i * 8), result[i]) }
	return i64(output_bytes)
}
