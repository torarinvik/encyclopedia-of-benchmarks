module matrix_det_arbitrary_mod

const max_n = 8
const max_input_values = 2 + max_n * max_n + 1
const max_modulus = i64(1_000_000_000)

fn normalize(value i64, modulus i64) i64 {
	mut residue := value % modulus
	if residue < 0 { residue += modulus }
	return residue
}

fn store_i64_le(mut output &u8, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'matrix_det_arbitrary_mod']
pub fn matrix_det_arbitrary_mod(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	n_value := unsafe { input[0] }
	modulus := unsafe { input[1] }
	if n_value < 0 || n_value > max_n || modulus < 2 || modulus > max_modulus { return -1 }
	n := int(n_value)
	if length != usize(2 + n * n) { return -1 }

	mut matrix := []i64{len: max_n * max_n}
	for row in 0 .. n {
		for column in 0 .. n {
			value := unsafe { input[2 + row * n + column] }
			if value < 0 || value >= modulus { return -1 }
			matrix[row * n + column] = value
		}
	}

	mut determinant := i64(1)
	mut sign := false
	for column in 0 .. n {
		mut pivot := column
		for pivot < n && matrix[pivot * n + column] == 0 { pivot++ }
		if pivot == n {
			determinant = 0
			break
		}
		if pivot != column {
			for k in 0 .. n {
				matrix[column * n + k], matrix[pivot * n + k] = matrix[pivot * n + k], matrix[column * n + k]
			}
			sign = !sign
		}
		for row in column + 1 .. n {
			mut left := matrix[column * n + column]
			mut right := matrix[row * n + column]
			if right == 0 { continue }
			mut a0 := i64(1)
			mut a1 := i64(0)
			mut b0 := i64(0)
			mut b1 := i64(1)
			for left != 0 && right != 0 {
				if left < right {
					quotient := right / left
					right -= quotient * left
					b0 = normalize(b0 - a0 * quotient, modulus)
					b1 = normalize(b1 - a1 * quotient, modulus)
				} else {
					quotient := left / right
					left -= quotient * right
					a0 = normalize(a0 - b0 * quotient, modulus)
					a1 = normalize(a1 - b1 * quotient, modulus)
				}
			}
			for k in column .. n {
				old_top := matrix[column * n + k]
				old_bottom := matrix[row * n + k]
				matrix[column * n + k] = normalize(old_top * a0 + old_bottom * a1, modulus)
				matrix[row * n + k] = normalize(old_top * b0 + old_bottom * b1, modulus)
			}
			if left == 0 {
				for k in 0 .. n {
					matrix[column * n + k], matrix[row * n + k] = matrix[row * n + k], matrix[column * n + k]
				}
				sign = !sign
			}
		}
		determinant = determinant * matrix[column * n + column] % modulus
		if determinant == 0 { break }
	}
	if sign && determinant != 0 { determinant = modulus - determinant }
	if unsafe { output == nil } || capacity < 8 { return -2 }
	store_i64_le(mut output, determinant)
	return 8
}
