module tsvc_s312_array_product

const max_n = 48
const max_input_length = 1 + max_n
const max_value = i64(2)

@[export: 'tsvc_s312_array_product']
pub fn tsvc_s312_array_product(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 0 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + n { return -1 }

	mut product := i64(1)
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < 0 || value > max_value { return -1 }
		product *= value
	}
	return product
}
