package dynamic_mex_updates

import "core:c"

MAX_N :: 32
MAX_Q :: 32
MAX_OUTPUT_BYTES :: 8 * MAX_Q

tree_set :: proc "contextless" (tree: [^]int, base, value, present: int) {
	node := base + value
	tree[node] = present
	node /= 2
	for node > 0 {
		tree[node] = tree[2 * node] + tree[2 * node + 1]
		node /= 2
	}
}

find_mex :: proc "contextless" (tree: [^]int, base, domain_size: int) -> int {
	node, start, span := 1, 0, base
	for span > 1 {
		half := span / 2
		left_width := 0
		if start < domain_size do left_width = min(half, domain_size - start)
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

write_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 do output[offset + byte] = u8(bits >> (8 * byte))
}

@(export)
dynamic_mex_updates :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 99 do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if int(length) != 2 + n + 2 * q do return -1
	current: [MAX_N]i64 = {}
	update_indices: [MAX_Q]int = {}
	update_values: [MAX_Q]i64 = {}
	for index := 0; index < n; index += 1 {
		value := input[2 + index]
		if value < -1000 || value > 1000 do return -1
		current[index] = value
	}
	cursor := 2 + n
	for operation := 0; operation < q; operation += 1 {
		index, value := input[cursor], input[cursor + 1]
		cursor += 2
		if index < 0 || index >= n_value || value < -1000 || value > 1000 do return -1
		update_indices[operation], update_values[operation] = int(index), value
	}
	needed := 8 * q
	if needed > 0 && (output == nil || int(capacity) < needed) do return -2
	base := 1
	for base < n + 1 do base *= 2
	frequencies: [MAX_N + 1]int = {}
	tree: [128]int = {}
	for index := 0; index < n; index += 1 {
		value := current[index]
		if value >= 0 && value <= n_value do frequencies[int(value)] += 1
	}
	for value := 0; value < n + 1; value += 1 {
		if frequencies[value] > 0 do tree[base + value] = 1
	}
	for node := base - 1; node > 0; node -= 1 do tree[node] = tree[2 * node] + tree[2 * node + 1]
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for operation := 0; operation < q; operation += 1 {
		index := update_indices[operation]
		old_value, new_value := current[index], update_values[operation]
		if old_value != new_value {
			if old_value >= 0 && old_value <= n_value {
				old_index := int(old_value)
				frequencies[old_index] -= 1
				if frequencies[old_index] == 0 do tree_set(&tree[0], base, old_index, 0)
			}
			if new_value >= 0 && new_value <= n_value {
				new_index := int(new_value)
				if frequencies[new_index] == 0 do tree_set(&tree[0], base, new_index, 1)
				frequencies[new_index] += 1
			}
			current[index] = new_value
		}
		write_i64(&staged[0], 8 * operation, i64(find_mex(&tree[0], base, n + 1)))
	}
	for byte := 0; byte < needed; byte += 1 do output[byte] = staged[byte]
	return i64(needed)
}
