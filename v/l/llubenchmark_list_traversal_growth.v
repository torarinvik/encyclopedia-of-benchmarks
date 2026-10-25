const max_lists = 4
const max_initial_length = 4
const max_iterations = 16
const max_nodes = 36

fn store_le_i64(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> (8 * byte)) & 255)
		}
	}
}

@[export: 'llubenchmark_list_traversal_growth']
pub fn llubenchmark_list_traversal_growth(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length != 3 { return -1 }
	list_value := unsafe { input[0] }
	initial_value := unsafe { input[1] }
	iteration_value := unsafe { input[2] }
	if list_value < 1 || list_value > max_lists || initial_value < 1 || initial_value > max_initial_length || iteration_value < 0 || iteration_value > max_iterations { return -1 }
	if unsafe { output == nil } || output_capacity < 16 { return -2 }
	list_count := int(list_value)
	initial_length := int(initial_value)
	iterations := int(iteration_value)
	mut next_node := [max_nodes]i64{}
	mut node_count := [max_nodes]i64{}
	mut head := [max_lists]i64{}
	mut tail := [max_lists]i64{}
	for i in 0 .. max_nodes { next_node[i] = -1 }
	for i in 0 .. max_lists { head[i] = -1; tail[i] = -1 }
	mut allocated := 0
	for _ in 0 .. initial_length {
		for list in 0 .. list_count {
			node := allocated
			allocated++
			next_node[node] = head[list]
			head[list] = i64(node)
			if tail[list] == -1 { tail[list] = i64(node) }
		}
	}
	mut accumulate := i64(0)
	mut growth_milli := 0
	for _ in 0 .. iterations {
		for list in 0 .. list_count {
			mut node := head[list]
			for node != -1 {
				index := int(node)
				accumulate += node_count[index]
				node_count[index]++
				node = next_node[index]
			}
		}
		growth_milli += 333
		insertions := growth_milli / 1000
		growth_milli -= insertions * 1000
		for ordinal := insertions; ordinal > 0; ordinal-- {
			for list in 0 .. list_count {
				node := allocated
				allocated++
				node_count[node] = i64(list + ordinal)
				next_node[node] = -1
				next_node[int(tail[list])] = i64(node)
				tail[list] = i64(node)
			}
		}
	}
	store_le_i64(output, 0, accumulate)
	store_le_i64(output, 8, i64(allocated))
	return 2
}
