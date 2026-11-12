module connected_components_of_complement_graph

const max_n = 64
const max_m = max_n * (max_n - 1) / 2
const max_input_values = 2 + 2 * max_m
const max_output_values = 1 + 2 * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'connected_components_of_complement_graph']
pub fn connected_components_of_complement_graph(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values {
		return -1
	}
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || m_value < 0 {
		return -1
	}
	if m_value > n_value * (n_value - 1) / 2 {
		return -1
	}
	n := int(n_value)
	m := int(m_value)
	if length != usize(2 + 2 * m) {
		return -1
	}

	mut graph := []u64{len: max_n}
	for edge in 0 .. m {
		left_value := unsafe { input[2 + 2 * edge] }
		right_value := unsafe { input[3 + 2 * edge] }
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value {
			return -1
		}
		left := int(left_value)
		right := int(right_value)
		bit := u64(1) << right
		if (graph[left] & bit) != 0 {
			return -1
		}
		graph[left] |= bit
		graph[right] |= u64(1) << left
	}

	mut remaining := []int{len: max_n}
	mut queue := []int{len: max_n}
	mut label := []int{len: max_n, init: -1}
	for vertex in 0 .. n {
		remaining[vertex] = vertex
	}
	mut remaining_count := n
	mut component_count := 0
	for remaining_count > 0 {
		remaining_count--
		root := remaining[remaining_count]
		label[root] = component_count
		mut head := 0
		mut tail := 1
		queue[0] = root
		for head < tail {
			current := queue[head]
			head++
			mut position := 0
			for position < remaining_count {
				candidate := remaining[position]
				if ((graph[current] >> candidate) & 1) != 0 {
					position++
				} else {
					remaining_count--
					remaining[position] = remaining[remaining_count]
					label[candidate] = component_count
					queue[tail] = candidate
					tail++
				}
			}
		}
		component_count++
	}

	mut staged := []i64{len: max_output_values}
	mut used := 0
	staged[used] = i64(component_count)
	used++
	mut emitted := []bool{len: max_n}
	for first in 0 .. n {
		component := label[first]
		if emitted[component] {
			continue
		}
		emitted[component] = true
		mut component_size := 0
		for vertex in 0 .. n {
			if label[vertex] == component {
				component_size++
			}
		}
		staged[used] = i64(component_size)
		used++
		for vertex in 0 .. n {
			if label[vertex] == component {
				staged[used] = i64(vertex)
				used++
			}
		}
	}

	required := 8 * used
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	for index in 0 .. used {
		store_i64_le(mut output, 8 * index, staged[index])
	}
	return i64(required)
}
