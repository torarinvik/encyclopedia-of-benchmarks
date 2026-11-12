module unionfind_with_potential_non_commutative_group

const max_n = 32
const max_q = 64
const modulus = i64(998_244_353)

type Matrix = [4]i64

fn normalize(value_input i64) i64 {
	mut value := value_input % modulus
	if value < 0 { value += modulus }
	return value
}

fn matrix_multiply(left Matrix, right Matrix) Matrix {
	mut result := Matrix{}
	for row in 0 .. 2 {
		for column in 0 .. 2 {
			for inner in 0 .. 2 {
				index := 2 * row + column
				result[index] = normalize(result[index] + left[2 * row + inner] * right[2 * inner + column])
			}
		}
	}
	return result
}

fn matrix_inverse(matrix Matrix) Matrix {
	mut result := [4]i64{}
	result[0] = matrix[3]
	result[1] = normalize(-matrix[1])
	result[2] = normalize(-matrix[2])
	result[3] = matrix[0]
	return result
}

fn find_root(mut parent [max_n]int, mut difference [max_n]Matrix, item int) int {
	if parent[item] != item {
		old_parent := parent[item]
		root := find_root(mut parent, mut difference, old_parent)
		difference[item] = matrix_multiply(difference[old_parent], difference[item])
		parent[item] = root
	}
	return parent[item]
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'unionfind_with_potential_non_commutative_group']
pub fn unionfind_with_potential_non_commutative_group(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 9 || length > usize(2 + 7 * max_q) { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q { return -1 }
		n, q := int(n_value), int(q_value)
		if length != usize(2 + 7 * q) { return -1 }
		for operation in 0 .. q {
			position := 2 + 7 * operation
			kind, u, v := input[position], input[position+1], input[position+2]
			if u < 0 || u >= n_value || v < 0 || v >= n_value { return -1 }
			if kind == 0 {
				a, b, c, d := input[position+3], input[position+4], input[position+5], input[position+6]
				if a < 0 || a >= modulus || b < 0 || b >= modulus || c < 0 || c >= modulus || d < 0 || d >= modulus || normalize(a*d-b*c) != 1 { return -1 }
			} else if kind == 1 {
				for cell in 0 .. 4 { if input[position+3+cell] != 0 { return -1 } }
			} else { return -1 }
		}
		required := 32 * q
		if output == nil || capacity < usize(required) { return -2 }
		mut parent := [max_n]int{}
		mut set_size := [max_n]int{}
		mut difference := [max_n]Matrix{}
		for item in 0 .. n { parent[item] = item; set_size[item] = 1; difference[item] = [4]i64{1,0,0,1} }
		for operation in 0 .. q {
			position := 2 + 7 * operation
			kind := input[position]
			u, v := int(input[position+1]), int(input[position+2])
			mut row := Matrix{}
			root_u := find_root(mut parent, mut difference, u)
			root_v := find_root(mut parent, mut difference, v)
			if kind == 1 {
				if root_u == root_v {
					row = matrix_multiply(matrix_inverse(difference[v]), difference[u])
				} else {
					for cell in 0 .. 4 { row[cell] = -1 }
				}
			} else {
			mut relation := [4]i64{}
			for cell in 0 .. 4 { relation[cell] = input[position+3+cell] }
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
			for cell in 0 .. 4 { put_i64_le(mut output, 32*operation+8*cell, row[cell]) }
		}
		return i64(required)
	}
}
