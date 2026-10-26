module hub_labeling_pruned

const max_vertices = 8
const max_edges = 28
const max_input = 66
const max_fields = 73
const max_output_bytes = 8 * max_fields

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn unique_shortest_paths(adjacency &u8, n int) bool {
	unsafe {
		for source in 0 .. n {
			mut distance := [max_vertices]i16{init: -1}
			mut ways := [max_vertices]u8{init: 0}
			mut queue := [max_vertices]int{init: 0}
			mut head := 0
			mut tail := 0
			distance[source] = 0; ways[source] = 1; queue[tail] = source; tail++
			for head < tail {
				vertex := queue[head]; head++
				for neighbor in 0 .. n {
					if adjacency[vertex * max_vertices + neighbor] == 0 { continue }
					if distance[neighbor] < 0 {
						distance[neighbor] = distance[vertex] + 1
						ways[neighbor] = ways[vertex]
						queue[tail] = neighbor; tail++
					} else if distance[neighbor] == distance[vertex] + 1 {
						ways[neighbor] = u8(if int(ways[neighbor]) + int(ways[vertex]) > 1 { 2 } else { int(ways[neighbor]) + int(ways[vertex]) })
					}
				}
			}
			for vertex in 0 .. n { if ways[vertex] != 1 { return false } }
		}
	}
	return true
}

@[export: 'hub_labeling_pruned']
pub fn hub_labeling_pruned(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(2 + n + 2*m) { return -1 }
		mut seen_order := [max_vertices]bool{init: false}
		for i in 0 .. n {
			vertex := input[2 + i]
			if vertex < 0 || vertex >= n_value || seen_order[int(vertex)] { return -1 }
			seen_order[int(vertex)] = true
		}
		mut adjacency := [max_vertices * max_vertices]u8{init: 0}
		mut previous_left := i64(-1)
		mut previous_right := i64(-1)
		for edge in 0 .. m {
			left, right := input[2 + n + 2*edge], input[3 + n + 2*edge]
			if left < 0 || right <= left || right >= n_value || left < previous_left || (left == previous_left && right <= previous_right) { return -1 }
			previous_left, previous_right = left, right
			adjacency[int(left) * max_vertices + int(right)] = 1
			adjacency[int(right) * max_vertices + int(left)] = 1
		}
		if !unique_shortest_paths(&adjacency[0], n) { return -1 }
		mut labels := [max_vertices * max_vertices]i16{init: -1}
		for order_index in 0 .. n {
			hub := int(input[2 + order_index])
			mut distance := [max_vertices]i16{init: -1}
			mut queue := [max_vertices]int{init: 0}
			mut head := 0
			mut tail := 0
			distance[hub] = 0; queue[tail] = hub; tail++
			for head < tail {
				vertex := queue[head]; head++
				mut estimate := i16(2 * max_vertices)
				for common in 0 .. n {
					from_hub := labels[hub * max_vertices + common]
					from_vertex := labels[vertex * max_vertices + common]
					if from_hub >= 0 && from_vertex >= 0 && from_hub + from_vertex < estimate { estimate = from_hub + from_vertex }
				}
				if estimate <= distance[vertex] { continue }
				labels[vertex * max_vertices + hub] = distance[vertex]
				for neighbor in 0 .. n {
					if adjacency[vertex * max_vertices + neighbor] != 0 && distance[neighbor] < 0 {
						distance[neighbor] = distance[vertex] + 1
						queue[tail] = neighbor; tail++
					}
				}
			}
		}
		mut fields := [max_fields]i64{init: 0}
		mut field_count := 0
		fields[field_count] = i64(n); field_count++
		for vertex in 0 .. n {
			count_index := field_count; field_count++
			mut count := i64(0)
			for hub in 0 .. n {
				value := labels[vertex * max_vertices + hub]
				if value >= 0 { fields[field_count] = i64(hub) | (i64(value) << 8); field_count++; count++ }
			}
			fields[count_index] = count
		}
		bytes := field_count * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		for i in 0 .. field_count { store_i64_le(mut staged[..], i * 8, fields[i]) }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
