const max_text_length = 64
const max_input_length = 66
const max_output_bytes = 1536

@[export: 'lz77_java_compress']
pub fn lz77_java_compress(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_text_length { return -1 }
		text_length := int(input[0])
		if input_length != usize(1 + text_length) { return -1 }
		for index in 0 .. text_length {
			if input[index + 1] < 32 || input[index + 1] > 126 { return -1 }
		}

		mut staged := [max_output_bytes]u8{}
		mut token_count := 0
		mut current := 0
		for current < text_length {
			mut best_distance := 0
			mut best_length := 0
			search_start := if current > 4096 { current - 4096 } else { 0 }
			lookahead_end := if current + 16 < text_length { current + 16 } else { text_length }
			for candidate in search_start .. current {
				mut match_length := 0
				for current + match_length < lookahead_end {
					mut source := candidate + match_length
					if source >= current {
						distance := current - candidate
						source = candidate + match_length % distance
					}
					if input[source + 1] != input[current + match_length + 1] { break }
					match_length++
				}
				if match_length > best_length {
					best_distance = current - candidate
					best_length = match_length
				}
			}

			next_character := if current + best_length < text_length { input[current + best_length + 1] } else { i64(0) }
			fields := [3]i64{i64(best_distance), i64(best_length), next_character}
			byte_offset := token_count * 24
			for field in 0 .. 3 {
				bits := u64(fields[field])
				for byte in 0 .. 8 { staged[byte_offset + field * 8 + byte] = u8((bits >> (byte * 8)) & u64(0xff)) }
			}
			token_count++
			if next_character == 0 { current += best_length } else { current += best_length + 1 }
		}

		output_bytes := token_count * 24
		if output_bytes > max_output_bytes { return -1 }
		if output == nil || capacity < output_bytes { return -2 }
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
