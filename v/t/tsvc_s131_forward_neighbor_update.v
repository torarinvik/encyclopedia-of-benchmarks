module tsvc_s131_forward_neighbor_update

const max_n = 64
const max_input_length = 2 + 2 * max_n
const max_value = i64(1000000)
const max_passes = 32

fn bounded_value(value i64) bool {
	return value >= -max_value && value <= max_value
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tsvc_s131_forward_neighbor_update']
pub fn tsvc_s131_forward_neighbor_update(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	passes_raw := unsafe { input[1] }
	if n_raw < 1 || n_raw > max_n || passes_raw < 1 || passes_raw > max_passes { return -1 }
	n := int(n_raw)
	if int(length) != 2 + 2 * n { return -1 }

	mut a := [max_n]i64{}
	mut b := [max_n]i64{}
	for i in 0 .. n {
		a[i] = unsafe { input[2 + i] }
		b[i] = unsafe { input[2 + n + i] }
		if !bounded_value(a[i]) || !bounded_value(b[i]) { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }

	for _pass in 0 .. int(passes_raw) {
		for i in 0 .. n - 1 { a[i] = a[i + 1] + b[i] }
	}
	for i in 0 .. n { store_i64_le(mut output, 8 * i, a[i]) }
	return i64(n)
}
