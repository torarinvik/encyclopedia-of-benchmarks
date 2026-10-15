module camel_case_to_snake_case

@[export: 'camel_case_to_snake_case']
pub fn camel_case_to_snake_case(input &i64, length usize, output &u8, capacity usize) i64 {
	if length == 0 || length > 256 || unsafe { input == nil } { return -1 }
	mut output_length := usize(0)
	for i in 0 .. length {
		value := unsafe { input[i] }
		if value >= 65 && value <= 90 {
			if i > 0 { output_length++ }
		} else if value < 97 || value > 122 {
			return -1
		}
		output_length++
	}
	if capacity < output_length || unsafe { output == nil } { return -2 }
	mut position := usize(0)
	for i in 0 .. length {
		value := unsafe { input[i] }
		if value >= 65 && value <= 90 {
			if i > 0 {
				unsafe { output[position] = u8('_') }
				position++
			}
			unsafe { output[position] = u8(value + 32) }
		} else {
			unsafe { output[position] = u8(value) }
		}
		position++
	}
	return i64(output_length)
}
