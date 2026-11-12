package unionfind_with_potential_non_commutative_group

import "core:c"

max_n :: 32
max_q :: 64
modulus :: i64(998_244_353)
Matrix :: [4]i64

normalize :: proc(value_input: i64) -> i64 {
	value := value_input % modulus
	if value < 0 { value += modulus }
	return value
}

matrix_multiply :: proc(left, right: Matrix) -> Matrix {
	result := Matrix{}
	for row := 0; row < 2; row += 1 {
		for column := 0; column < 2; column += 1 {
			for inner := 0; inner < 2; inner += 1 {
				index := 2 * row + column
				result[index] = normalize(result[index] + left[2 * row + inner] * right[2 * inner + column])
			}
		}
	}
	return result
}

matrix_inverse :: proc(matrix: Matrix) -> Matrix {
	return Matrix{matrix[3], normalize(-matrix[1]), normalize(-matrix[2]), matrix[0]}
}

find_root :: proc(parent: ^[max_n]int, difference: ^[max_n]Matrix, item: int) -> int {
	if parent[item] != item {
		old_parent := parent[item]
		root := find_root(parent, difference, old_parent)
		difference[item] = matrix_multiply(difference[old_parent], difference[item])
		parent[item] = root
	}
	return parent[item]
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
unionfind_with_potential_non_commutative_group :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 9 || length > 2 + 7 * max_q { return -1 }
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q { return -1 }
	n, q := int(n_value), int(q_value)
	if int(length) != 2 + 7 * q { return -1 }
	for operation := 0; operation < q; operation += 1 {
		position := 2 + 7 * operation
		kind, u, v := input[position], input[position+1], input[position+2]
		if u < 0 || u >= n_value || v < 0 || v >= n_value { return -1 }
		if kind == 0 {
			a, b, c0, d := input[position+3], input[position+4], input[position+5], input[position+6]
			if a < 0 || a >= modulus || b < 0 || b >= modulus || c0 < 0 || c0 >= modulus || d < 0 || d >= modulus || normalize(a*d-b*c0) != 1 { return -1 }
		} else if kind == 1 {
			for cell := 0; cell < 4; cell += 1 { if input[position+3+cell] != 0 { return -1 } }
		} else { return -1 }
	}
	required := 32 * q
	if output == nil || int(capacity) < required { return -2 }
	parent: [max_n]int
	set_size: [max_n]int
	difference: [max_n]Matrix
	for item := 0; item < n; item += 1 { parent[item] = item; set_size[item] = 1; difference[item] = Matrix{1, 0, 0, 1} }
	for operation := 0; operation < q; operation += 1 {
		position := 2 + 7 * operation
		kind := input[position]
		u, v := int(input[position+1]), int(input[position+2])
		row := Matrix{}
		root_u := find_root(&parent, &difference, u)
		root_v := find_root(&parent, &difference, v)
		if kind == 1 {
			if root_u == root_v { row = matrix_multiply(matrix_inverse(difference[v]), difference[u]) } else { row = Matrix{-1, -1, -1, -1} }
		} else {
			relation := Matrix{input[position+3], input[position+4], input[position+5], input[position+6]}
			if root_u == root_v {
				row[0] = i64(matrix_multiply(matrix_inverse(difference[v]), difference[u]) == relation)
			} else if set_size[root_u] < set_size[root_v] {
				first := matrix_multiply(difference[v], relation)
				difference[root_u] = matrix_multiply(first, matrix_inverse(difference[u]))
				parent[root_u] = root_v; set_size[root_v] += set_size[root_u]; row[0] = 1
			} else {
				first := matrix_multiply(difference[u], matrix_inverse(relation))
				difference[root_v] = matrix_multiply(first, matrix_inverse(difference[v]))
				parent[root_v] = root_u; set_size[root_u] += set_size[root_v]; row[0] = 1
			}
		}
		for cell := 0; cell < 4; cell += 1 { put_i64_le(output, 32*operation+8*cell, row[cell]) }
	}
	return i64(required)
}
