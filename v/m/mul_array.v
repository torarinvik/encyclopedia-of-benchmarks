module mul_array

const max_input_length = 9

@[export: 'mul_array']
pub fn mul_array(values &i64, length usize) i64 {
	if length > max_input_length { return -1 }
	if length == 0 { return 1 }
	unsafe {
		if values == nil { return -1 }
		mut product := i64(1)
		for index in 0 .. int(length) {
			value := values[index]
			if value < 0 || value > 99 { return -1 }
			product *= value
		}
		return product
	}
}
