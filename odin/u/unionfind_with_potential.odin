package unionfind_with_potential

import "core:c"

max_n :: 64
max_q :: 256
modulus :: i64(998_244_353)

normalize :: proc(value_input: i64) -> i64 {
	value := value_input % modulus
	if value < 0 { value += modulus }
	return value
}

find_root :: proc(parent: ^[max_n]int, difference: ^[max_n]i64, item: int) -> int {
	if parent[item] != item {
		old_parent := parent[item]
		root := find_root(parent, difference, old_parent)
		difference[item] = normalize(difference[item] + difference[old_parent])
		parent[item] = root
	}
	return parent[item]
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
unionfind_with_potential :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 2 + 4 * max_q { return -1 }
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q { return -1 }
	n, q := int(n_value), int(q_value)
	if int(length) != 2 + 4 * q { return -1 }
	for operation := 0; operation < q; operation += 1 {
		position := 2 + 4 * operation
		kind, u, v, x := input[position], input[position+1], input[position+2], input[position+3]
		if u < 0 || u >= n_value || v < 0 || v >= n_value { return -1 }
		if kind == 0 {
			if x < 0 || x >= modulus { return -1 }
		} else if kind == 1 {
			if x != 0 { return -1 }
		} else { return -1 }
	}
	required := 8 * q
	if output == nil || capacity < c.size_t(required) { return -2 }
	parent: [max_n]int
	set_size: [max_n]int
	difference: [max_n]i64
	for item := 0; item < n; item += 1 { parent[item] = item; set_size[item] = 1 }
	for operation := 0; operation < q; operation += 1 {
		position := 2 + 4 * operation
		kind := input[position]
		u, v, x := int(input[position+1]), int(input[position+2]), input[position+3]
		root_u := find_root(&parent, &difference, u)
		root_v := find_root(&parent, &difference, v)
		answer: i64
		if kind == 1 {
			if root_u == root_v { answer = normalize(difference[u] - difference[v]) } else { answer = -1 }
		} else if root_u == root_v {
			answer = i64(normalize(difference[u] - difference[v]) == x)
		} else if set_size[root_u] < set_size[root_v] {
			parent[root_u] = root_v
			difference[root_u] = normalize(x - difference[u] + difference[v])
			set_size[root_v] += set_size[root_u]
			answer = 1
		} else {
			parent[root_v] = root_u
			difference[root_v] = normalize(difference[u] - difference[v] - x)
			set_size[root_u] += set_size[root_v]
			answer = 1
		}
		put_i64_le(output, 8 * operation, answer)
	}
	return i64(required)
}
