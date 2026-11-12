module matrix_product_mod_2

const max_dimension = 64
const max_input_values = 3 + 2 * max_dimension * max_dimension
const max_output_values = max_dimension * max_dimension

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'matrix_product_mod_2']
pub fn matrix_product_mod_2(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_values { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	k_value := unsafe { input[2] }
	if n_value < 1 || n_value > max_dimension || m_value < 1 || m_value > max_dimension ||
		k_value < 1 || k_value > max_dimension { return -1 }
	n, m, k := int(n_value), int(m_value), int(k_value)
	a_length := n * m
	b_length := m * k
	if length != usize(3 + a_length + b_length) { return -1 }

	mut packed_b := []u64{len: max_dimension}
	b_start := 3 + a_length
	for inner in 0 .. m {
		for column in 0 .. k {
			bit := unsafe { input[b_start + inner * k + column] }
			if bit != 0 && bit != 1 { return -1 }
			packed_b[inner] |= u64(bit) << u64(column)
		}
	}

	mut staged := []i64{len: max_output_values}
	for row in 0 .. n {
		mut accumulator := u64(0)
		for inner in 0 .. m {
			bit := unsafe { input[3 + row * m + inner] }
			if bit != 0 && bit != 1 { return -1 }
			if bit == 1 { accumulator ^= packed_b[inner] }
		}
		for column in 0 .. k {
			staged[row * k + column] = i64((accumulator >> u64(column)) & 1)
		}
	}

	required := 8 * n * k
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for index in 0 .. n * k { store_i64_le(mut output, 8 * index, staged[index]) }
	return i64(required)
}
