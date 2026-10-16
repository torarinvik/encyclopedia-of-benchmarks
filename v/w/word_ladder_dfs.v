module word_ladder_dfs

const max_words = 8
const max_path_words = max_words + 1
const max_input_length = 4 + max_words
const max_output_fields = max_path_words + max_words + 2

fn power_of_26(exponent int) i64 {
	mut result := i64(1)
	for _ in 0 .. exponent { result *= 26 }
	return result
}

fn find_active_word(words &i64, active &u8, count int, candidate i64) int {
	for index in 0 .. count {
		if unsafe { active[index] != 0 && words[index] == candidate } { return index }
	}
	return count
}

fn backtrack(current i64, target i64, width int, words &i64, count int,
	mut active &u8, mut path &i64, mut path_length &int) bool {
	if current == target { return true }
	for position in 0 .. width {
		factor := power_of_26(width-position-1)
		digit := (current / factor) % 26
		for replacement in 0 .. 26 {
			candidate := current + (i64(replacement)-digit)*factor
			index := find_active_word(words, active, count, candidate)
			if index == count { continue }
			unsafe { active[index] = 0; path[path_length[0]] = candidate }
			path_length[0]++
			if backtrack(candidate,target,width,words,count,mut active,mut path,mut path_length) { return true }
			path_length[0]--
			unsafe { active[index] = 1 }
		}
	}
	return false
}

fn write_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset+byte] = u8(bits & 255); bits >>= 8 } }
}

@[export: 'word_ladder_dfs']
pub fn word_ladder_dfs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input_length { return -1 }
		width_value, begin_word, end_word, count_value := input[0], input[1], input[2], input[3]
		if width_value < 1 || width_value > 5 || count_value < 0 || count_value > max_words ||
			length != usize(4+count_value) { return -1 }
		width, count := int(width_value), int(count_value)
		limit := power_of_26(width)
		if begin_word < 0 || begin_word >= limit || end_word < 0 || end_word >= limit { return -1 }
		words := &input[4]
		for index in 0 .. count {
			if words[index] < 0 || words[index] >= limit || (index > 0 && words[index-1] >= words[index]) { return -1 }
		}
		mut active := [max_words]u8{}
		for index in 0 .. count { active[index] = 1 }
		mut path := [max_path_words]i64{}
		path[0] = begin_word
		mut path_length := 1
		if find_active_word(words, &active[0], count, end_word) != count {
			if !backtrack(begin_word,end_word,width,words,count,mut active[0],mut path[0],mut path_length) { path_length = 0 }
		} else { path_length = 0 }
		mut scratch := [max_output_fields]i64{}
		mut fields := 0
		scratch[fields] = i64(path_length); fields++
		for index in 0 .. path_length { scratch[fields] = path[index]; fields++ }
		mut remaining := 0
		for index in 0 .. count { if active[index] != 0 { remaining++ } }
		scratch[fields] = i64(remaining); fields++
		for index in 0 .. count { if active[index] != 0 { scratch[fields] = words[index]; fields++ } }
		required := fields * 8
		if output == nil || capacity < usize(required) { return -2 }
		for index in 0 .. fields { write_i64_le(mut output, index*8, scratch[index]) }
		return i64(required)
	}
}
