package rabin_karp

import "core:c"

// Test ASCII pattern presence with a Rabin-Karp rolling hash.
@(export)
rabin_karp :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 512 do return -1
	text_length_value := values[0]
	pattern_length_value := values[1]
	if text_length_value < 0 || text_length_value > 255 || pattern_length_value < 0 || pattern_length_value > 255 do return -1
	if length != c.size_t(2 + text_length_value + pattern_length_value) do return -1
	for index := c.size_t(0); index < c.size_t(text_length_value + pattern_length_value); index += 1 {
		if values[2 + index] < 0 || values[2 + index] > 127 do return -1
	}

	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if pattern_length == 0 do return 1
	if pattern_length > text_length do return 0

	pattern_hash := i64(0)
	rolling_hash := i64(0)
	high_power := i64(1)
	for index := 0; index < pattern_length; index += 1 {
		pattern_hash = (pattern_hash * 256 + values[2 + c.size_t(text_length) + c.size_t(index)]) % 1000003
		rolling_hash = (rolling_hash * 256 + values[2 + c.size_t(index)]) % 1000003
		if index + 1 < pattern_length do high_power = (high_power * 256) % 1000003
	}

	last_start := text_length - pattern_length
	for start := 0; start <= last_start; start += 1 {
		if rolling_hash == pattern_hash {
			equal := true
			for offset := 0; offset < pattern_length; offset += 1 {
				if values[2 + c.size_t(start + offset)] != values[2 + c.size_t(text_length + offset)] {
					equal = false
					break
				}
			}
			if equal do return 1
		}
		if start < last_start {
			removed := (values[2 + c.size_t(start)] * high_power) % 1000003
			rolling_hash = (rolling_hash - removed) % 1000003
			if rolling_hash < 0 do rolling_hash += 1000003
			rolling_hash = (rolling_hash * 256 + values[2 + c.size_t(start + pattern_length)]) % 1000003
		}
	}
	return 0
}
