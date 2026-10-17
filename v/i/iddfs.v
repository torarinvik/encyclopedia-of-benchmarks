module iddfs

const max_vertices = 16
const max_neighbors = 64
const max_depth = 8
const max_valid_input_length = 4 + 2 * max_vertices + max_neighbors
const max_parseable_input_length = max_valid_input_length + 1
const max_path_length = max_depth + 1
const max_output_values = 3 + max_path_length

fn store_i64_le(mut output []u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@[export: 'iddfs']
pub fn iddfs(values &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 4 || length > max_parseable_input_length { return -1 }
	unsafe {
		raw_start := values[0]
		raw_target := values[1]
		raw_depth := values[2]
		raw_entries := values[3]
		if raw_start < 1 || raw_start > i64(max_vertices) || raw_target < 1 || raw_target > i64(max_vertices) ||
			raw_depth < 0 || raw_depth > i64(max_depth) || raw_entries < 0 || raw_entries > i64(max_vertices) { return -1 }
		start := int(raw_start)
		target := int(raw_target)
		depth_limit := int(raw_depth)
		entry_count := int(raw_entries)

		mut adjacency := [max_vertices * max_neighbors]i32{}
		mut degree_count := [max_vertices]int{}
		mut named := [max_vertices]bool{}
		mut max_vertex := 0
		mut total_neighbors := 0
		mut cursor := 4
		for _ in 0 .. entry_count {
			if cursor + 2 > int(length) { return -1 }
			raw_vertex := values[cursor]
			cursor++
			raw_degree := values[cursor]
			cursor++
			if raw_vertex < 1 || raw_vertex > i64(max_vertices) || raw_degree < 0 || raw_degree > i64(max_neighbors) { return -1 }
			vertex := int(raw_vertex)
			degree := int(raw_degree)
			if named[vertex - 1] || degree > int(length) - cursor || total_neighbors + degree > max_neighbors { return -1 }
			named[vertex - 1] = true
			if vertex > max_vertex { max_vertex = vertex }
			total_neighbors += degree
			for _ in 0 .. degree {
				raw_neighbor := values[cursor]
				cursor++
				if raw_neighbor < -i64(max_vertices) || raw_neighbor > i64(max_vertices) { return -1 }
				if raw_neighbor > i64(max_vertex) { max_vertex = int(raw_neighbor) }
				if raw_neighbor >= 1 {
					slot := (vertex - 1) * max_neighbors + degree_count[vertex - 1]
					adjacency[slot] = i32(raw_neighbor)
					degree_count[vertex - 1]++
				}
			}
		}
		if cursor != int(length) { return -1 }
		if max_vertex != 0 && (start > max_vertex || target > max_vertex) { return -1 }

		mut path := [max_path_length]int{}
		mut next_neighbor := [max_path_length]int{}
		mut path_length := 0
		mut found_depth := 0
		mut found := false
		if max_vertex != 0 {
			for limit := 0; limit <= depth_limit && !found; limit++ {
				path_length = 1
				path[0] = start
				next_neighbor[0] = 0
				if start == target {
					found = true
					found_depth = 0
					break
				}
				for path_length > 0 && !found {
					frame := path_length - 1
					current := path[frame]
					if frame >= limit || next_neighbor[frame] >= degree_count[current - 1] {
						path_length--
						continue
					}
					slot := (current - 1) * max_neighbors + next_neighbor[frame]
					neighbor := int(adjacency[slot])
					next_neighbor[frame]++
					mut prior := 0
					for prior < path_length && path[prior] != neighbor { prior++ }
					if prior != path_length { continue }
					path[path_length] = neighbor
					path_length++
					if neighbor == target {
						found = true
						found_depth = path_length - 1
					} else {
						next_neighbor[path_length - 1] = 0
					}
				}
			}
		}

		mut result := [max_output_values]i64{}
		mut result_count := 3
		result[0] = 0
		result[1] = -1
		result[2] = 0
		if found {
			result[0] = 1
			result[1] = i64(found_depth)
			result[2] = i64(path_length)
			result_count += path_length
			for index in 0 .. path_length { result[3 + index] = i64(path[index]) }
		}
		required := result_count * 8
		if output == nil || capacity < usize(required) { return -2 }
		for index in 0 .. result_count { store_i64_le(mut output[..], 8 * index, result[index]) }
		return i64(required)
	}
}
