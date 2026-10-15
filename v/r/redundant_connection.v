module redundant_connection

const max_vertices = 1000

fn find_root(mut parents []i32, node_value int) int {
	mut node := node_value
	mut root := node
	for parents[root] != root { root = parents[root] }
	for parents[node] != node {
		next := parents[node]
		parents[node] = root
		node = next
	}
	return root
}

// Return the edge that first closes the cycle under input-order union-find.
@[export: 'redundant_connection']
pub fn redundant_connection(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length < 6 || length > max_vertices * 2 || length % 2 != 0 { return -1 }
	count := int(length) / 2
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 1 || value > i64(count) { return -1 }
	}
	for edge in 0 .. count {
		if unsafe { values[2 * edge] == values[2 * edge + 1] } { return -1 }
	}

	mut parents := []i32{len: count + 1}
	for node in 0 .. count + 1 { parents[node] = node }
	mut redundant_left := i64(0)
	mut redundant_right := i64(0)
	mut redundant_count := 0
	for edge in 0 .. count {
		left := int(unsafe { values[2 * edge] })
		right := int(unsafe { values[2 * edge + 1] })
		left_root := find_root(mut parents, left)
		right_root := find_root(mut parents, right)
		if left_root == right_root {
			redundant_left = i64(left)
			redundant_right = i64(right)
			redundant_count++
		} else {
			parents[left_root] = right_root
		}
	}
	if redundant_count != 1 { return -1 }
	if output_capacity < 8 { return -2 }
	for endpoint, value in [redundant_left, redundant_right] {
		bits := u32(value)
		for byte in 0 .. 4 {
			unsafe { output[endpoint * 4 + byte] = u8((bits >> (byte * 8)) & 255) }
		}
	}
	return 2
}
