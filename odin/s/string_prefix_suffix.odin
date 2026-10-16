package string_prefix_suffix

import "core:c"

MAX_CODE_UNITS :: 1024

// mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units.
@(export)
string_prefix_suffix :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 2052 do return -1
	mode := values[0]
	text_count_value := values[1]
	pattern_count_value := values[2]
	if (mode != 0 && mode != 1) || text_count_value < 0 || text_count_value > MAX_CODE_UNITS ||
		pattern_count_value < 0 || pattern_count_value > MAX_CODE_UNITS do return -1
	text_count := int(text_count_value)
	pattern_count := int(pattern_count_value)
	if length != c.size_t(3 + text_count + pattern_count) do return -1
	for index := 0; index < text_count + pattern_count; index += 1 {
		unit := values[3 + index]
		if unit < 0 || unit > 65535 do return -1
	}
	if pattern_count > text_count do return 0
	start := 0
	if mode == 1 do start = text_count - pattern_count
	for index := 0; index < pattern_count; index += 1 {
		if values[3 + start + index] != values[3 + text_count + index] do return 0
	}
	return 1
}
