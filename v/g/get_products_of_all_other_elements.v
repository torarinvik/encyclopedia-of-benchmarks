module get_products_of_all_other_elements

const max_array_length = 32
const max_input_length = usize(34)

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'get_products_of_all_other_elements']
pub fn get_products_of_all_other_elements(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_array_length { return -1 }
	n := int(n_value)
	if length != usize(n + 1) { return -1 }
	mut result := [max_array_length]i64{init: 0}
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -2 || value > 2 { return -1 }
	}
	if n < 2 { return 0 }
	output_bytes := usize(n * 8)
	if unsafe { output == nil } || capacity < output_bytes { return -2 }

	result[0] = 1
	for i in 0 .. n - 1 { result[i + 1] = unsafe { input[i + 1] } * result[i] }
	mut suffix := i64(1)
	for i := n - 1; i > 0; i-- {
		value := unsafe { input[i + 1] }
		result[i - 1] *= suffix * value
		suffix *= value
	}
	for i in 0 .. n { write_i64_le(mut output, i * 8, result[i]) }
	return i64(output_bytes)
}
