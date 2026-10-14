module rabin_karp

// Test ASCII pattern presence with a Rabin-Karp rolling hash.
@[export: 'rabin_karp']
pub fn rabin_karp(values &i64, length usize) i64 {
	if length < 2 || length > 512 { return -1 }
	text_length_value := unsafe { values[0] }
	pattern_length_value := unsafe { values[1] }
	if text_length_value < 0 || text_length_value > 255 || pattern_length_value < 0 || pattern_length_value > 255 { return -1 }
	if length != usize(2 + text_length_value + pattern_length_value) { return -1 }
	for index in 0 .. usize(text_length_value + pattern_length_value) {
		value := unsafe { values[2 + index] }
		if value < 0 || value > 127 { return -1 }
	}

	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if pattern_length == 0 { return 1 }
	if pattern_length > text_length { return 0 }

	mut pattern_hash := i64(0)
	mut rolling_hash := i64(0)
	mut high_power := i64(1)
	for index in 0 .. pattern_length {
		pattern_hash = (pattern_hash * 256 + unsafe { values[2 + usize(text_length + index)] }) % 1000003
		rolling_hash = (rolling_hash * 256 + unsafe { values[2 + usize(index)] }) % 1000003
		if index + 1 < pattern_length { high_power = (high_power * 256) % 1000003 }
	}

	last_start := text_length - pattern_length
	for start in 0 .. last_start + 1 {
		if rolling_hash == pattern_hash {
			mut equal := true
			for offset in 0 .. pattern_length {
				if unsafe { values[2 + usize(start + offset)] } != unsafe { values[2 + usize(text_length + offset)] } {
					equal = false
					break
				}
			}
			if equal { return 1 }
		}
		if start < last_start {
			removed := (unsafe { values[2 + usize(start)] } * high_power) % 1000003
			rolling_hash = (rolling_hash - removed) % 1000003
			if rolling_hash < 0 { rolling_hash += 1000003 }
			rolling_hash = (rolling_hash * 256 + unsafe { values[2 + usize(start + pattern_length)] }) % 1000003
		}
	}
	return 0
}
