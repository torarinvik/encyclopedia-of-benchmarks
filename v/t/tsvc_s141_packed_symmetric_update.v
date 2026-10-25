module tsvc_s141_packed_symmetric_update

const max_n = 16
const max_triangle = max_n * (max_n + 1) / 2
const max_input_length = 2 + max_triangle + max_n * max_n
const max_value = i64(1000000)
const max_rounds = 32

fn bounded_value(value i64) bool {
	return value >= -max_value && value <= max_value
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tsvc_s141_packed_symmetric_update']
pub fn tsvc_s141_packed_symmetric_update(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	rounds_raw := unsafe { input[1] }
	if n_raw < 1 || n_raw > max_n || rounds_raw < 1 || rounds_raw > max_rounds { return -1 }
	n := int(n_raw)
	triangle := n * (n + 1) / 2
	matrix_start := 2 + triangle
	if int(length) != matrix_start + n * n { return -1 }

	mut packed := [max_triangle]i64{}
	for p in 0 .. triangle {
		packed[p] = unsafe { input[2 + p] }
		if !bounded_value(packed[p]) { return -1 }
	}
	for p in 0 .. n * n {
		if !bounded_value(unsafe { input[matrix_start + p] }) { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(8 * triangle) { return -2 }

	for _round in 0 .. int(rounds_raw) {
		for i in 0 .. n {
			for j in i .. n {
				k := j * (j + 1) / 2 + i
				packed[k] += unsafe { input[matrix_start + j * n + i] }
			}
		}
	}
	for p in 0 .. triangle { store_i64_le(mut output, 8 * p, packed[p]) }
	return i64(triangle)
}
