module snake_case_to_camel_pascal_case

@[export: 'snake_case_to_camel_pascal_case']
pub fn snake_case_to_camel_pascal_case(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 257 { return -1 }
	mode := unsafe { input[0] }
	if mode != 0 && mode != 1 { return -1 }
	input_length := length - 1
	mut output_length := usize(0)
	for i in 0 .. input_length {
		value := unsafe { input[i + 1] }
		if value == 95 {
			if i == 0 || i + 1 == input_length || unsafe { input[i] == 95 } { return -1 }
		} else if !((value >= 97 && value <= 122) || (value >= 48 && value <= 57)) {
			return -1
		} else {
			output_length++
		}
	}
	if capacity < output_length || unsafe { output == nil } { return -2 }
	mut capitalize := mode == 1
	mut position := usize(0)
	for i in 0 .. input_length {
		mut value := unsafe { input[i + 1] }
		if value == 95 {
			capitalize = true
			continue
		}
		if capitalize && value >= 97 && value <= 122 { value -= 32 }
		unsafe { output[position] = u8(value) }
		position++
		capitalize = false
	}
	return i64(output_length)
}
