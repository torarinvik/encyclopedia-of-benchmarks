module tsvc_s321_first_order_recurrence

const max_n = 64
const max_input_length = 1 + 2 * max_n

fn bounded_value(value i64) bool { return value >= -1 && value <= 1 }

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s321_first_order_recurrence']
pub fn tsvc_s321_first_order_recurrence(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 1 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + 2 * n { return -1 }

	a_start := 1
	b_start := a_start + n
	for i in 0 .. n {
		if !bounded_value(unsafe { input[a_start + i] }) || !bounded_value(unsafe { input[b_start + i] }) { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }

	mut a := [max_n]i64{}
	for i in 0 .. n { a[i] = unsafe { input[a_start + i] } }
	for i := 1; i < n; i++ { a[i] += a[i - 1] * unsafe { input[b_start + i] } }
	for i in 0 .. n { store_i64_le(mut output, 8 * i, a[i]) }
	return i64(n)
}
