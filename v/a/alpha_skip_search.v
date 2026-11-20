module alpha_skip_search

const max_text_length = 4096
const max_pattern_length = 128
const max_buckets = 64
const max_input_length = 4227

@[export: 'alpha_skip_search']
pub fn alpha_skip_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		text_length64, pattern_length64 := input[0], input[1]
		if text_length64 < 0 || text_length64 > max_text_length || pattern_length64 < 1 || pattern_length64 > max_pattern_length { return -1 }
		text_length, pattern_length := int(text_length64), int(pattern_length64)
		if int(length) != 2 + text_length + pattern_length { return -1 }
		mut text := [max_text_length]u8{}
		mut pattern := [max_pattern_length]u8{}
		for i in 0 .. text_length {
			symbol := input[2 + i]
			if symbol < 0 || symbol > 3 { return -1 }
			text[i] = u8(symbol)
		}
		pattern_offset := 2 + text_length
		for i in 0 .. pattern_length {
			symbol := input[pattern_offset + i]
			if symbol < 0 || symbol > 3 { return -1 }
			pattern[i] = u8(symbol)
		}

		mut factor_length := 1
		mut bucket_count := 4
		for bucket_count * 4 <= pattern_length {
			bucket_count *= 4
			factor_length++
		}
		factor_count := pattern_length - factor_length + 1
		mut factor_power := 1
		for _ in 1 .. factor_length { factor_power *= 4 }
		mut heads := [max_buckets]int{init: -1}
		mut next_position := [max_pattern_length]int{}
		mut code := 0
		for i in 0 .. factor_length { code = code * 4 + int(pattern[i]) }
		for position in 0 .. factor_count {
			if position > 0 { code = (code - int(pattern[position - 1]) * factor_power) * 4 + int(pattern[position + factor_length - 1]) }
			next_position[position] = heads[code]
			heads[code] = position
		}
		if text_length < pattern_length { return 0 }
		shift := pattern_length - factor_length + 1
		mut match_count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		mut sample_start := 0
		for sample_start <= text_length - factor_length {
			mut text_code := 0
			for offset in 0 .. factor_length { text_code = text_code * 4 + int(text[sample_start + offset]) }
			mut pattern_position := heads[text_code]
			for pattern_position >= 0 {
				candidate := sample_start - pattern_position
				if candidate >= 0 && candidate <= text_length - pattern_length {
					mut matches := true
					for offset in 0 .. pattern_length {
						if text[candidate + offset] != pattern[offset] { matches = false; break }
					}
					if matches {
						match_count++
					 offset_sum += i64(candidate)
					 offset_xor ^= i64(candidate)
					}
				}
				pattern_position = next_position[pattern_position]
			}
			sample_start += shift
		}
		return (match_count << 36) | (offset_sum << 12) | offset_xor
	}
}
