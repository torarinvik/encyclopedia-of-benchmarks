package crochemore_perrin_two_way

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_PATTERN_LENGTH :: 32
MAX_INPUT_LENGTH :: 99

maximal_suffix :: proc "contextless" (pattern: [^]i64, length: int,
		reverse_order: bool, state: [^]int) {
	maximal := -1
	candidate := 0
	offset := 1
	period := 1
	for candidate+offset < length {
		a := pattern[candidate+offset]
		b := pattern[maximal+offset]
		precedes := if reverse_order do a > b else do a < b
		if precedes {
			candidate += offset
			offset = 1
			period = candidate-maximal
		} else if a == b {
			if offset != period { offset += 1 }
			else { candidate += period; offset = 1 }
		} else {
			maximal = candidate
			candidate = maximal+1
			offset = 1
			period = 1
		}
	}
	state[0] = maximal
	state[1] = period
}

two_way :: proc "contextless" (text, pattern: [^]i64, text_length, pattern_length: int,
		matches: [^]i64) -> int {
	match_count := 0
	if pattern_length == 0 {
		for i := 0; i <= text_length; i += 1 { matches[match_count] = i64(i); match_count += 1 }
		return match_count
	}
	if pattern_length > text_length do return 0

	first: [2]int = 0
	second: [2]int = 0
	maximal_suffix(pattern, pattern_length, false, raw_data(first[:]))
	maximal_suffix(pattern, pattern_length, true, raw_data(second[:]))
	critical := if first[0] > second[0] do first[0] else do second[0]
	period := if first[0] > second[0] do first[1] else do second[1]
	periodic := period+critical+1 <= pattern_length
	if periodic {
		for i := 0; i <= critical; i += 1 {
			if pattern[i] != pattern[i+period] { periodic = false; break }
		}
	}
	shift := period
	if !periodic {
		other_half := pattern_length-critical-1
		shift = (if critical > other_half do critical else do other_half)+1
	}
	memory := -1
	start := 0
	for start <= text_length-pattern_length {
		index := critical+1
		if periodic && memory > critical { index = memory+1 }
		for index < pattern_length && pattern[index] == text[start+index] { index += 1 }
		if index >= pattern_length {
			index = critical
			for index > memory && pattern[index] == text[start+index] { index -= 1 }
			if index <= memory { matches[match_count] = i64(start); match_count += 1 }
			start += shift
			memory = if periodic do pattern_length-period-1 else do -1
		} else {
			start += index-critical
			memory = -1
		}
	}
	return match_count
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(byte*8)) }
}

@(export)
crochemore_perrin_two_way :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if values[0] < 0 || values[0] > MAX_TEXT_LENGTH || values[1] < 0 || values[1] > MAX_PATTERN_LENGTH do return -1
	text_length, pattern_length := int(values[0]), int(values[1])
	if length != c.size_t(2+text_length+pattern_length) do return -1
	text: [MAX_TEXT_LENGTH]i64 = 0
	pattern: [MAX_PATTERN_LENGTH]i64 = 0
	for i := 0; i < text_length; i += 1 {
		value := values[2+i]
		if value < 0 || value > 255 do return -1
		text[i] = value
	}
	for i := 0; i < pattern_length; i += 1 {
		value := values[2+text_length+i]
		if value < 0 || value > 255 do return -1
		pattern[i] = value
	}
	matches: [MAX_TEXT_LENGTH+1]i64 = 0
	match_count := two_way(raw_data(text[:]), raw_data(pattern[:]), text_length, pattern_length, raw_data(matches[:]))
	output_bytes := match_count*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < match_count; i += 1 { store_i64_le(output, i*8, matches[i]) }
	return i64(output_bytes)
}
