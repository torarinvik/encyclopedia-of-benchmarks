module string_prefix_suffix

// mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units.
@[export: 'string_prefix_suffix']
pub fn string_prefix_suffix(values &i64, length usize) i64 {
	if length < 3 || length > 2052 { return -1 }
	mode := unsafe { values[0] }
	text_count_value := unsafe { values[1] }
	pattern_count_value := unsafe { values[2] }
	if (mode != 0 && mode != 1) || text_count_value < 0 || text_count_value > 1024 ||
		pattern_count_value < 0 || pattern_count_value > 1024 { return -1 }
	text_count := int(text_count_value)
	pattern_count := int(pattern_count_value)
	if length != usize(3 + text_count + pattern_count) { return -1 }
	for index in 0 .. text_count + pattern_count {
		unit := unsafe { values[3 + index] }
		if unit < 0 || unit > 65535 { return -1 }
	}
	if pattern_count > text_count { return 0 }
	mut start := 0
	if mode == 1 { start = text_count - pattern_count }
	for index in 0 .. pattern_count {
		if unsafe { values[3 + start + index] } != unsafe { values[3 + text_count + index] } { return 0 }
	}
	return 1
}
