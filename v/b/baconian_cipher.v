module baconian_cipher

fn python_code_for_letter(upper int) int {
	if upper >= 65 && upper <= 73 { return upper - 65 }
	if upper == 74 { return 28 }
	if upper >= 75 && upper <= 85 { return upper - 66 }
	if upper == 86 { return 29 }
	if upper >= 87 && upper <= 90 { return upper - 67 }
	return -1
}

fn python_letter_for_code(code int) int {
	if code >= 0 && code <= 8 { return 97 + code }
	if code == 28 { return 106 }
	if code == 29 { return 118 }
	if code >= 9 && code <= 19 { return 97 + code + 1 }
	if code >= 20 && code <= 23 { return 97 + code + 2 }
	return -1
}

fn decode_code(values &i64, start int) int {
	mut code := 0
	for bit in 0 .. 5 {
		value := unsafe { values[start + bit] }
		code = (code << 1) | if value == 66 { 1 } else { 0 }
	}
	return code
}


fn write_code(output &u8, position int, code int) int {
	mut write := position
	for bit := 4; bit >= 0; bit-- {
		unsafe { output[write] = if ((code >> bit) & 1) != 0 { u8(66) } else { u8(65) } }
		write++
	}
	return write
}

fn python_decode_length(values &i64, n int) int {
	mut words := 0
	mut letters := 0
	mut used := 0
	mut code := 0
	mut in_word := false
	for i in 0 .. n {
		value := unsafe { values[2 + i] }
		if value == 32 {
			if used != 0 { return -1 }
			if in_word { words++; in_word = false }
		} else {
			if value != 65 && value != 66 { return -1 }
			in_word = true
			code = (code << 1) | if value == 66 { 1 } else { 0 }
			used++
			if used == 5 {
				if python_letter_for_code(code) < 0 { return -1 }
				letters++; used = 0; code = 0
			}
		}
	}
	if used != 0 { return -1 }
	if in_word { words++ }
	return letters + if words > 0 { words - 1 } else { 0 }
}

@[export: 'baconian_cipher']
pub fn baconian_cipher(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > 1026 { return -1 }
	mode := unsafe { values[0] }
	dialect := unsafe { values[1] }
	if (mode != 0 && mode != 1) || dialect < 0 || dialect > 2 { return -1 }
	n := int(length) - 2
	for i in 0 .. n {
		value := unsafe { values[i + 2] }
		if value < 0 || value > 127 { return -1 }
	}

	if mode == 0 {
		for i in 0 .. n {
			value := unsafe { values[i + 2] }
			upper := if value >= 97 && value <= 122 { value - 32 } else { value }
			is_letter := upper >= 65 && upper <= 90
			if dialect == 1 && value != 32 && !is_letter { return -1 }
			if dialect == 2 && is_letter && upper > 88 { return -1 }
		}
	}

	mut output_length := 0
	if mode == 0 {
		for i in 0 .. n {
			value := unsafe { values[i + 2] }
			upper := if value >= 97 && value <= 122 { value - 32 } else { value }
			is_letter := upper >= 65 && upper <= 90
			if dialect == 0 { if is_letter { output_length += 5 } }
			else if dialect == 1 { if value == 32 { output_length++ } else if is_letter { output_length += 5 } }
			else { if is_letter { output_length += 5 } else { output_length++ } }
		}
	} else if dialect == 0 {
		if n % 5 != 0 { return -1 }
		for i in 0 .. n {
			value := unsafe { values[i + 2] }
			if value != 65 && value != 66 { return -1 }
		}
		for i := 0; i < n; i += 5 { if decode_code(values, 2 + i) > 25 { return -1 } }
		output_length = n / 5
	} else if dialect == 1 {
		output_length = python_decode_length(values, n)
		if output_length < 0 { return -1 }
	} else { output_length = (n + 4) / 5 }
	if output_capacity < usize(output_length) { return -2 }

	mut write := 0
	if mode == 0 {
		for i in 0 .. n {
			value := unsafe { values[i + 2] }
			upper := if value >= 97 && value <= 122 { value - 32 } else { value }
			if dialect == 0 {
				if upper >= 65 && upper <= 90 { write = write_code(output, write, if upper == 73 { 9 } else { int(upper - 65) }) }
			} else if dialect == 1 {
				if value == 32 { unsafe { output[write] = 32 }; write++ }
				else { write = write_code(output, write, python_code_for_letter(int(upper))) }
			} else {
				if upper >= 65 && upper <= 90 { write = write_code(output, write, int(upper - 65)) }
				else { unsafe { output[write] = u8(value) }; write++ }
			}
		}
	} else if dialect == 0 {
		for i := 0; i < n; i += 5 {
			code := decode_code(values, 2 + i)
			unsafe { output[write] = u8(if code == 8 || code == 9 { 73 } else { 65 + code }) }
			write++
		}
	} else if dialect == 1 {
		mut i := 0
		mut first_word := true
		for i < n {
			for i < n && unsafe { values[2 + i] } == 32 { i++ }
			if i == n { break }
			if !first_word { unsafe { output[write] = 32 }; write++ }
			first_word = false
			for i < n && unsafe { values[2 + i] } != 32 {
				unsafe { output[write] = u8(python_letter_for_code(decode_code(values, 2 + i))) }
				write++; i += 5
			}
		}
	} else {
		for i := 0; i < n; i += 5 {
			if n - i < 5 { unsafe { output[write] = 32 }; write++; break }
			mut code := 0
			mut valid := true
			for bit in 0 .. 5 {
				value := unsafe { values[2 + i + bit] }
				if value != 65 && value != 66 { valid = false }
				code = (code << 1) | if value == 66 { 1 } else { 0 }
			}
			unsafe { output[write] = u8(if valid && code < 24 { 65 + code } else { 32 }) }
			write++
		}
	}
	return i64(output_length)
}
