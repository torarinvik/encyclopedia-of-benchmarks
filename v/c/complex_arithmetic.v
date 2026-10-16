module complex_arithmetic

const output_bytes = 16

fn store_i64_le(mut output &u8, position int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'complex_arithmetic']
pub fn complex_arithmetic(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 5 { return -1 }
	operation := unsafe { input[0] }
	ar := unsafe { input[1] }; ai := unsafe { input[2] }; br := unsafe { input[3] }; bi := unsafe { input[4] }
	if operation < 0 || operation > 5 { return -1 }
	if ar < -100000 || ar > 100000 { return -1 }
	if ai < -100000 || ai > 100000 { return -1 }
	if br < -100000 || br > 100000 { return -1 }
	if bi < -100000 || bi > 100000 { return -1 }

	mut real_result := i64(0)
	mut imaginary_result := i64(0)
	if operation == 0 {
		real_result = ar + br
		imaginary_result = ai + bi
	} else if operation == 1 {
		real_result = ar - br
		imaginary_result = ai - bi
	} else if operation == 2 {
		real_result = ar * br - ai * bi
		imaginary_result = ar * bi + ai * br
	} else if operation == 3 {
		denominator := br * br + bi * bi
		if denominator == 0 { return -1 }
		real_numerator := ar * br + ai * bi
		imaginary_numerator := ai * br - ar * bi
		if real_numerator % denominator != 0 || imaginary_numerator % denominator != 0 { return -1 }
		real_result = real_numerator / denominator
		imaginary_result = imaginary_numerator / denominator
	} else if operation == 4 {
		real_result = ar
		imaginary_result = -ai
	} else if ar == br && ai == bi {
		real_result = 1
	}
	if output_capacity < output_bytes || unsafe { output == nil } { return -2 }
	store_i64_le(mut output, 0, real_result)
	store_i64_le(mut output, 8, imaginary_result)
	return 2
}
