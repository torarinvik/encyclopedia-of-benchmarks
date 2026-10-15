package baconian_cipher

import "core:c"

python_code_for_letter :: proc(upper: i64) -> int {
	if upper >= 65 && upper <= 73 do return int(upper - 65)
	if upper == 74 do return 28
	if upper >= 75 && upper <= 85 do return int(upper - 66)
	if upper == 86 do return 29
	if upper >= 87 && upper <= 90 do return int(upper - 67)
	return -1
}

python_letter_for_code :: proc(code: int) -> int {
	if code >= 0 && code <= 8 do return 97 + code
	if code == 28 do return 106
	if code == 29 do return 118
	if code >= 9 && code <= 19 do return 97 + code + 1
	if code >= 20 && code <= 23 do return 97 + code + 2
	return -1
}

decode_code :: proc(values: [^]i64, start: int) -> int {
	code := 0
	for bit := 0; bit < 5; bit += 1 { code = (code << 1) | int(values[start + bit] == 66) }
	return code
}

write_code :: proc(output: [^]u8, position: int, code: int) -> int {
	write := position
	for bit := 4; bit >= 0; bit -= 1 {
		if ((code >> bit) & 1) != 0 { output[write] = 66 } else { output[write] = 65 }
		write += 1
	}
	return write
}

python_decode_length :: proc(values: [^]i64, n: int) -> int {
	words := 0; letters := 0; used := 0; code := 0; in_word := false
	for i := 0; i < n; i += 1 {
		value := values[2 + i]
		if value == 32 {
			if used != 0 do return -1
			if in_word { words += 1; in_word = false }
		} else {
			if value != 65 && value != 66 do return -1
			in_word = true
			code = (code << 1) | int(value == 66)
			used += 1
			if used == 5 {
				if python_letter_for_code(code) < 0 do return -1
				letters += 1; used = 0; code = 0
			}
		}
	}
	if used != 0 do return -1
	if in_word do words += 1
	return letters + max(0, words - 1)
}

@(export)
baconian_cipher :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 1026 do return -1
	mode := values[0]; dialect := values[1]
	if (mode != 0 && mode != 1) || dialect < 0 || dialect > 2 do return -1
	n := int(length) - 2
	for i := 0; i < n; i += 1 { if values[2 + i] < 0 || values[2 + i] > 127 do return -1 }

	if mode == 0 {
		for i := 0; i < n; i += 1 {
			value := values[2 + i]
			upper := value; if value >= 97 && value <= 122 do upper -= 32
			is_letter := upper >= 65 && upper <= 90
			if dialect == 1 && value != 32 && !is_letter do return -1
			if dialect == 2 && is_letter && upper > 88 do return -1
		}
	}

	output_length := 0
	if mode == 0 {
		for i := 0; i < n; i += 1 {
			value := values[2 + i]
			upper := value; if value >= 97 && value <= 122 do upper -= 32
			is_letter := upper >= 65 && upper <= 90
			if dialect == 0 { if is_letter do output_length += 5 }
			else if dialect == 1 { if value == 32 { output_length += 1 } else if is_letter { output_length += 5 } }
			else { if is_letter { output_length += 5 } else { output_length += 1 } }
		}
	} else if dialect == 0 {
		if n % 5 != 0 do return -1
		for i := 0; i < n; i += 1 { if values[2 + i] != 65 && values[2 + i] != 66 do return -1 }
		for i := 0; i < n; i += 5 { if decode_code(values, 2 + i) > 25 do return -1 }
		output_length = n / 5
	} else if dialect == 1 {
		output_length = python_decode_length(values, n)
		if output_length < 0 do return -1
	} else { output_length = (n + 4) / 5 }
	if output_capacity < c.size_t(output_length) || (output_length > 0 && output == nil) do return -2

	write := 0
	if mode == 0 {
		for i := 0; i < n; i += 1 {
			value := values[2 + i]
			upper := value; if value >= 97 && value <= 122 do upper -= 32
			if dialect == 0 {
				if upper >= 65 && upper <= 90 {
					code := int(upper - 65); if upper == 73 do code = 9
					write = write_code(output, write, code)
				}
			} else if dialect == 1 {
				if value == 32 { output[write] = 32; write += 1 }
				else { write = write_code(output, write, python_code_for_letter(upper)) }
			} else {
				if upper >= 65 && upper <= 90 { write = write_code(output, write, int(upper - 65)) }
				else { output[write] = u8(value); write += 1 }
			}
		}
	} else if dialect == 0 {
		for i := 0; i < n; i += 5 {
			code := decode_code(values, 2 + i)
			value := 65 + code; if code == 8 || code == 9 do value = 73
			output[write] = u8(value); write += 1
		}
	} else if dialect == 1 {
		i := 0; first_word := true
		for i < n {
			for i < n && values[2 + i] == 32 { i += 1 }
			if i == n do break
			if !first_word { output[write] = 32; write += 1 }
			first_word = false
			for i < n && values[2 + i] != 32 {
				output[write] = u8(python_letter_for_code(decode_code(values, 2 + i)))
				write += 1; i += 5
			}
		}
	} else {
		for i := 0; i < n; i += 5 {
			if n - i < 5 { output[write] = 32; write += 1; break }
			code := 0; valid := true
			for bit := 0; bit < 5; bit += 1 {
				value := values[2 + i + bit]
				if value != 65 && value != 66 do valid = false
				code = (code << 1) | int(value == 66)
			}
			if valid && code < 24 { output[write] = u8(65 + code) } else { output[write] = 32 }
			write += 1
		}
	}
	return i64(output_length)
}
