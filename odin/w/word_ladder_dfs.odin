package word_ladder_dfs
import "core:c"

MAX_WORDS :: 8
MAX_PATH_WORDS :: MAX_WORDS + 1
MAX_INPUT_LENGTH :: 4 + MAX_WORDS
MAX_OUTPUT_FIELDS :: MAX_PATH_WORDS + MAX_WORDS + 2

power_of_26 :: proc "contextless" (exponent: int) -> i64 {
	result: i64 = 1
	for _ in 0 .. exponent { result *= 26 }
	return result
}

find_active_word :: proc "contextless" (words: [^]i64, active: [^]bool, count: int, candidate: i64) -> int {
	for index in 0 .. count { if active[index] && words[index] == candidate do return index }
	return count
}

backtrack :: proc "contextless" (current, target: i64, width: int,
								 words: [^]i64, count: int, active: [^]bool,
								 path: [^]i64, path_length: ^int) -> bool {
	if current == target do return true
	for position in 0 .. width {
		factor := power_of_26(width - position - 1)
		digit := (current / factor) % 26
		for replacement := 0; replacement < 26; replacement += 1 {
			candidate := current + (i64(replacement) - digit) * factor
			index := find_active_word(words, active, count, candidate)
			if index == count do continue
			active[index] = false
			path[path_length^] = candidate
			path_length^ += 1
			if backtrack(candidate, target, width, words, count, active, path, path_length) do return true
			path_length^ -= 1
			active[index] = true
		}
	}
	return false
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
word_ladder_dfs :: proc "c" (input: [^]i64, length: c.size_t,
							 output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	width_value, begin_word, end_word, count_value := input[0], input[1], input[2], input[3]
	if width_value < 1 || width_value > 5 || count_value < 0 || count_value > MAX_WORDS ||
		length != c.size_t(4 + count_value) do return -1
	width, count := int(width_value), int(count_value)
	limit := power_of_26(width)
	if begin_word < 0 || begin_word >= limit || end_word < 0 || end_word >= limit do return -1
	words := &input[4]
	for index in 0 .. count {
		if words[index] < 0 || words[index] >= limit || (index > 0 && words[index-1] >= words[index]) do return -1
	}
	active: [MAX_WORDS]bool
	for index in 0 .. count { active[index] = true }
	path: [MAX_PATH_WORDS]i64
	path[0] = begin_word
	path_length := 1
	if find_active_word(words, &active[0], count, end_word) != count {
		if !backtrack(begin_word, end_word, width, words, count, &active[0], &path[0], &path_length) do path_length = 0
	} else { path_length = 0 }

	scratch: [MAX_OUTPUT_FIELDS]i64
	fields := 0
	scratch[fields] = i64(path_length); fields += 1
	for index in 0 .. path_length { scratch[fields] = path[index]; fields += 1 }
	remaining := 0
	for index in 0 .. count { if active[index] { remaining += 1 } }
	scratch[fields] = i64(remaining); fields += 1
	for index in 0 .. count { if active[index] { scratch[fields] = words[index]; fields += 1 } }
	required := fields * 8
	if output == nil || capacity < c.size_t(required) do return -2
	for index in 0 .. fields { write_i64_le(output, index * 8, scratch[index]) }
	return i64(required)
}
