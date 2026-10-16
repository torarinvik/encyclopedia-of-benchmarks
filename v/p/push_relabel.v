module push_relabel

const max_vertices = 14
const augmented_vertices = 16
const max_input_length = 227
const max_capacity = i64(1_000_000)

@[export: 'push_relabel']
pub fn push_relabel(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	n64 := unsafe { input[0] }
	source_count64 := unsafe { input[1] }
	if n64 < 2 || n64 > max_vertices || source_count64 < 1 || source_count64 >= n64 { return -1 }
	n := int(n64)
	source_count := int(source_count64)
	sink_count_index := 2 + source_count
	if int(length) <= sink_count_index { return -1 }

	mut is_source := [max_vertices]bool{}
	mut is_sink := [max_vertices]bool{}
	mut sources := [max_vertices]int{}
	for index in 0 .. source_count {
		node64 := unsafe { input[2 + index] }
		if node64 < 0 || node64 >= n64 || is_source[int(node64)] { return -1 }
		sources[index] = int(node64)
		is_source[int(node64)] = true
	}
	sink_count64 := unsafe { input[sink_count_index] }
	if sink_count64 < 1 || sink_count64 > n64 - source_count64 { return -1 }
	sink_count := int(sink_count64)
	matrix_start := sink_count_index + 1 + sink_count
	if int(length) < matrix_start || int(length) != matrix_start + n * n { return -1 }
	for index in 0 .. sink_count {
		node64 := unsafe { input[sink_count_index + 1 + index] }
		if node64 < 0 || node64 >= n64 || is_sink[int(node64)] || is_source[int(node64)] { return -1 }
		is_sink[int(node64)] = true
	}

	mut residual := [augmented_vertices * augmented_vertices]i64{}
	mut source_out := [max_vertices]i64{}
	mut flow_limit := i64(0)
	for row in 0 .. n {
		for column in 0 .. n {
			capacity := unsafe { input[matrix_start + row * n + column] }
			if capacity < 0 || capacity > max_capacity || (row == column && capacity != 0) { return -1 }
			residual[row * augmented_vertices + column] = capacity
			if is_source[row] {
				source_out[row] += capacity
				flow_limit += capacity
			}
		}
	}
	super_source := n
	super_sink := n + 1
	for index in 0 .. source_count {
		residual[super_source * augmented_vertices + sources[index]] = source_out[sources[index]]
	}
	for index in 0 .. sink_count {
		sink := int(unsafe { input[sink_count_index + 1 + index] })
		residual[sink * augmented_vertices + super_sink] = flow_limit
	}

	mut height := [augmented_vertices]int{}
	mut excess := [augmented_vertices]i64{}
	mut active := [augmented_vertices]bool{}
	height[super_source] = n + 2
	for index in 0 .. source_count {
		source := sources[index]
		initial_excess := residual[super_source * augmented_vertices + source]
		residual[super_source * augmented_vertices + source] = 0
		residual[source * augmented_vertices + super_source] += initial_excess
		excess[source] += initial_excess
		if excess[source] > 0 { active[source] = true }
	}

	for {
		mut node := 0
		for node < n && !active[node] { node++ }
		if node == n { break }
		active[node] = false
		for excess[node] > 0 {
			mut pushed := false
			for neighbor in 0 .. n + 2 {
				if excess[node] == 0 { break }
				edge := node * augmented_vertices + neighbor
				if residual[edge] <= 0 || height[node] != height[neighbor] + 1 { continue }
				mut amount := excess[node]
				if residual[edge] < amount { amount = residual[edge] }
				residual[edge] -= amount
				residual[neighbor * augmented_vertices + node] += amount
				excess[node] -= amount
				previous_excess := excess[neighbor]
				excess[neighbor] += amount
				if neighbor < n && previous_excess == 0 { active[neighbor] = true }
				pushed = true
			}
			if excess[node] > 0 && !pushed {
				mut minimum_height := 1000
				for neighbor in 0 .. n + 2 {
					if residual[node * augmented_vertices + neighbor] > 0 && height[neighbor] < minimum_height {
						minimum_height = height[neighbor]
					}
				}
				if minimum_height == 1000 { return -1 }
				height[node] = minimum_height + 1
			}
		}
	}
	return excess[super_sink]
}
