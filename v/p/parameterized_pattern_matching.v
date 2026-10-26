module parameterized_pattern_matching

const max_text = 24
const max_pattern = 8
const max_input = 34
const max_output_bytes = 200
const alphabet = 16

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn predecessor_code(input &i64, offset int, count int, mut code []i64) {
	mut last := [alphabet]i64{init: -1}
	for index in 0 .. count {
		symbol := int(unsafe { input[offset + index] })
		code[index] = if last[symbol] < 0 { 0 } else { i64(index) - last[symbol] }
		last[symbol] = i64(index)
	}
}

@[export: 'parameterized_pattern_matching']
pub fn parameterized_pattern_matching(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		text_length_value, pattern_length_value := input[0], input[1]
		if text_length_value < 0 || text_length_value > max_text ||
			pattern_length_value < 1 || pattern_length_value > max_pattern { return -1 }
		text_length, pattern_length := int(text_length_value), int(pattern_length_value)
		if length != usize(2 + text_length + pattern_length) { return -1 }
		for index in 2 .. int(length) {
			if input[index] < 0 || input[index] >= alphabet { return -1 }
		}

		mut pattern_code := [max_pattern]i64{init: 0}
		predecessor_code(input, 2 + text_length, pattern_length, mut pattern_code[..])
		mut matches := [max_text]int{init: 0}
		mut match_count := 0
		if pattern_length <= text_length {
			for start in 0 .. text_length - pattern_length + 1 {
				mut window_code := [max_pattern]i64{init: 0}
				predecessor_code(input, 2 + start, pattern_length, mut window_code[..])
				mut same := true
				for index in 0 .. pattern_length {
					if pattern_code[index] != window_code[index] { same = false }
				}
				if same { matches[match_count] = start; match_count++ }
			}
		}

		output_bytes := 8 * (match_count + 1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		store_i64_le(mut staged[..], 0, i64(match_count))
		for index in 0 .. match_count { store_i64_le(mut staged[..], 8 * (index + 1), i64(matches[index])) }
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
