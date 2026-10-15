const max_vertices = 7
const max_states = 4096

struct SearchState {
	distance   int
	heuristic  int
	path_length int
	path       [max_vertices]int
}

fn write_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte_index in 0 .. 8 {
			output[offset + byte_index] = u8((bits >> (byte_index * 8)) & 255)
		}
	}
}

@[export: 'astar_java_weighted_graph']
pub fn astar_java_weighted_graph(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 { return -1 }
		n64, m64, start64, target64 := input[0], input[1], input[2], input[3]
		if n64 < 1 || n64 > max_vertices || m64 < 0 || m64 > 16 ||
			start64 < 0 || start64 >= n64 || target64 < 0 || target64 >= n64 ||
			length != usize(4 + n64 + 3 * m64) { return -1 }
		n, m, start, target := int(n64), int(m64), int(start64), int(target64)
		mut heuristic := [max_vertices]int{}
		mut adjacent := [max_vertices][max_vertices]int{}
		mut weights := [max_vertices][max_vertices]int{}
		mut degree := [max_vertices]int{}
		for i in 0 .. n {
			if input[4 + i] < -1000 || input[4 + i] > 1000 { return -1 }
			heuristic[i] = int(input[4 + i])
		}
		mut position := 4 + n
		for _ in 0 .. m {
			u64, v64, weight64 := input[position], input[position + 1], input[position + 2]
			position += 3
			if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 || weight64 < 0 || weight64 > 1000 { return -1 }
			u, v := int(u64), int(v64)
			for i in 0 .. degree[u] { if adjacent[u][i] == v { return -1 } }
			adjacent[u][degree[u]] = v
			weights[u][degree[u]] = int(weight64)
			degree[u]++
			adjacent[v][degree[v]] = u
			weights[v][degree[v]] = int(weight64)
			degree[v]++
		}
		mut states := [max_states]SearchState{}
		mut heap := [max_states]int{}
		mut state_count := 1
		mut heap_size := 1
		states[0] = SearchState{distance: 0, heuristic: heuristic[start], path_length: 1}
		states[0].path[0] = start
		heap[0] = 0
		mut found := false
		mut solution := 0
		for heap_size > 0 {
			current_index := heap[0]
			last := heap[heap_size - 1]
			heap_size--
			if heap_size > 0 {
				mut i := 0
				half := heap_size / 2
				for i < half {
					mut child := 2 * i + 1
					mut child_index := heap[child]
					right := child + 1
					if right < heap_size && states[heap[right]].distance + states[heap[right]].heuristic < states[child_index].distance + states[child_index].heuristic {
						child = right
						child_index = heap[right]
					}
					if states[last].distance + states[last].heuristic <= states[child_index].distance + states[child_index].heuristic { break }
					heap[i] = child_index
					i = child
				}
				heap[i] = last
			}
			current := states[current_index]
			current_vertex := current.path[current.path_length - 1]
			if current_vertex == target { found = true; solution = current_index; break }
			for edge in 0 .. degree[current_vertex] {
				next := adjacent[current_vertex][edge]
				mut in_path := false
				for i in 0 .. current.path_length { if current.path[i] == next { in_path = true; break } }
				if in_path { continue }
				if state_count >= max_states || heap_size >= max_states { return -1 }
				mut child_state := SearchState{distance: current.distance + weights[current_vertex][edge], heuristic: heuristic[next], path_length: current.path_length + 1}
				for i in 0 .. current.path_length { child_state.path[i] = current.path[i] }
				child_state.path[current.path_length] = next
				states[state_count] = child_state
				next_state := state_count
				state_count++
				mut i := heap_size
				heap_size++
				for i > 0 {
					parent := (i - 1) / 2
					parent_index := heap[parent]
					if states[parent_index].distance + states[parent_index].heuristic <= child_state.distance + child_state.heuristic { break }
					heap[i] = parent_index
					i = parent
				}
				heap[i] = next_state
			}
		}
		mut result := [10]i64{}
		mut result_words := 3
		if !found { result[0], result[1], result[2] = -1, -1, 0 }
		else {
			state := states[solution]
			result[0], result[1], result[2] = i64(state.distance), i64(state.heuristic), i64(state.path_length)
			result_words += state.path_length
			for i in 0 .. state.path_length { result[3 + i] = i64(state.path[i]) }
		}
		output_bytes := result_words * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. result_words { write_i64(mut output, i * 8, result[i]) }
		return i64(output_bytes)
	}
}
