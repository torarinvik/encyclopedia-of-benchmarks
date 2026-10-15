module binary_or_operator

@[export: 'binary_or_operator']
pub fn binary_or_operator(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	a_value := unsafe { input[0] }
	b_value := unsafe { input[1] }
	if a_value < 0 || a_value > 2147483647 || b_value < 0 || b_value > 2147483647 { return -1 }
	a := u64(a_value); b := u64(b_value)
	mut largest := if a > b { a } else { b }
	mut width := 1
	for largest > 1 { largest >>= 1; width++ }
	output_length := width + 2
	if int(capacity) < output_length || unsafe { output == nil } { return -2 }
	unsafe { output[0] = u8('0'); output[1] = u8('b') }
	result := a | b
	for i in 0 .. width {
		bit := width - 1 - i
		char := if ((result >> bit) & 1) == 1 { u8('1') } else { u8('0') }
		unsafe { output[2 + i] = char }
	}
	return i64(output_length)
}
