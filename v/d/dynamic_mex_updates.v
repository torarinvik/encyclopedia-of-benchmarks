module dynamic_mex_updates

const max_n = 32
const max_q = 32
const max_output_bytes = 8 * max_q

fn tree_set(mut tree [128]int, base int, value int, present int) {
	mut node := base + value
	tree[node] = present
	node /= 2
	for node > 0 {
		tree[node] = tree[2 * node] + tree[2 * node + 1]
		node /= 2
	}
}

fn find_mex(tree [128]int, base int, domain_size int) int {
	mut node := 1
	mut start := 0
	mut span := base
	for span > 1 {
		half := span / 2
		left_width := if start >= domain_size { 0 } else { min(half, domain_size - start) }
		if tree[2 * node] < left_width {
			node *= 2
			span = half
		} else {
			node = 2 * node + 1
			start += half
			span = half
		}
	}
	return start
}

fn write_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'dynamic_mex_updates']
pub fn dynamic_mex_updates(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 99 { return -1 }
	unsafe {
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
		n, q := int(n_value), int(q_value)
		if int(length) != 2 + n + 2 * q { return -1 }
		mut current := [max_n]i64{}
		mut update_indices := [max_q]int{}
		mut update_values := [max_q]i64{}
		for index in 0 .. n {
			value := input[2 + index]
			if value < -1000 || value > 1000 { return -1 }
			current[index] = value
		}
		mut cursor := 2 + n
		for operation in 0 .. q {
			index, value := input[cursor], input[cursor + 1]
			cursor += 2
			if index < 0 || index >= n_value || value < -1000 || value > 1000 { return -1 }
			update_indices[operation] = int(index)
			update_values[operation] = value
		}
		needed := 8 * q
		if needed > 0 && (output == nil || capacity < usize(needed)) { return -2 }
		mut base := 1
		for base < n + 1 { base *= 2 }
		mut frequencies := [max_n + 1]int{}
		mut tree := [128]int{}
		for index in 0 .. n {
			value := current[index]
			if value >= 0 && value <= n_value { frequencies[int(value)]++ }
		}
		for value in 0 .. n + 1 { if frequencies[value] > 0 { tree[base + value] = 1 } }
		mut node := base - 1
		for node > 0 {
			tree[node] = tree[2 * node] + tree[2 * node + 1]
			node--
		}
		mut staged := [max_output_bytes]u8{}
		for operation in 0 .. q {
			index := update_indices[operation]
			old_value, new_value := current[index], update_values[operation]
			if old_value != new_value {
				if old_value >= 0 && old_value <= n_value {
					old_index := int(old_value)
					frequencies[old_index]--
					if frequencies[old_index] == 0 { tree_set(mut tree, base, old_index, 0) }
				}
				if new_value >= 0 && new_value <= n_value {
					new_index := int(new_value)
					if frequencies[new_index] == 0 { tree_set(mut tree, base, new_index, 1) }
					frequencies[new_index]++
				}
				current[index] = new_value
			}
			write_i64(mut staged[0], 8 * operation, i64(find_mex(tree, base, n + 1)))
		}
		for byte in 0 .. needed { output[byte] = staged[byte] }
		return i64(needed)
	}
}
