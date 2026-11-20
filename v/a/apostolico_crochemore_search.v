module apostolico_crochemore_search

const max_text_length = 4096
const max_pattern_length = 128
const max_parseable_length = 4227
const pattern_sentinel = u8(4)

fn build_kmp_next(pattern []u8, pattern_length int, mut next [129]i64) {
	mut i := 0
	mut j := i64(-1)
	next[0] = -1
	for i < pattern_length {
		for j > -1 && pattern[i] != pattern[int(j)] { j = next[int(j)] }
		i++
		j++
		following := if i < pattern_length { pattern[i] } else { pattern_sentinel }
		if following == pattern[int(j)] {
			next[i] = next[int(j)]
		} else {
			next[i] = j
		}
	}
}

@[export: 'apostolico_crochemore_search']
pub fn apostolico_crochemore_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_length { return -1 }
		text_length_value := input[0]
		pattern_length_value := input[1]
		if text_length_value < 0 || text_length_value > max_text_length ||
			pattern_length_value < 1 || pattern_length_value > max_pattern_length { return -1 }
		text_length := int(text_length_value)
		pattern_length := int(pattern_length_value)
		if length != usize(2 + text_length + pattern_length) { return -1 }

		mut text := [max_text_length]u8{}
		mut pattern := [max_pattern_length]u8{}
		for index in 0 .. text_length {
			value := input[2 + index]
			if value < 0 || value > 3 { return -1 }
			text[index] = u8(value)
		}
		pattern_offset := 2 + text_length
		for index in 0 .. pattern_length {
			value := input[pattern_offset + index]
			if value < 0 || value > 3 { return -1 }
			pattern[index] = u8(value)
		}

		mut kmp_next := [max_pattern_length + 1]i64{}
		build_kmp_next(pattern[..], pattern_length, mut kmp_next)
		mut ell := 1
		for ell < pattern_length && pattern[ell - 1] == pattern[ell] { ell++ }
		if ell == pattern_length { ell = 0 }

		mut match_count := i64(0)
		mut sum_offsets := i64(0)
		mut xor_offsets := i64(0)
		if text_length >= pattern_length {
			mut i := ell
			mut j := 0
			mut k := 0
			for j <= text_length - pattern_length {
				for i < pattern_length && pattern[i] == text[j + i] { i++ }
				if i >= pattern_length {
					for k < ell && pattern[k] == text[j + k] { k++ }
					if k >= ell {
						match_count++
						sum_offsets += i64(j)
						xor_offsets ^= i64(j)
					}
				}

				j += int(i64(i) - kmp_next[i])
				if i == ell {
					if k > 0 { k-- }
				} else if kmp_next[i] <= i64(ell) {
					k = if kmp_next[i] > 0 { int(kmp_next[i]) } else { 0 }
					i = ell
				} else {
					k = ell
					i = int(kmp_next[i])
				}
			}
		}

		return (match_count << 36) | (sum_offsets << 12) | xor_offsets
	}
}
