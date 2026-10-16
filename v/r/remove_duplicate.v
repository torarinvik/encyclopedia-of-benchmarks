module remove_duplicate

fn compare_words(values &i64, start_a int, length_a int, start_b int, length_b int) int {
	common := if length_a < length_b { length_a } else { length_b }
	for index in 0 .. common {
		a := unsafe { values[1 + start_a + index] }
		b := unsafe { values[1 + start_b + index] }
		if a < b { return -1 }
		if a > b { return 1 }
	}
	if length_a < length_b { return -1 }
	if length_a > length_b { return 1 }
	return 0
}

@[export: 'remove_duplicate']
pub fn remove_duplicate(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 { return -1 }
	text_value := unsafe { values[0] }
	if text_value < 0 || text_value > 1024 || length != usize(1 + text_value) { return -1 }
	text_length := int(text_value)
	for index in 0 .. text_length {
		byte := unsafe { values[index + 1] }
		if byte != 32 && (byte < 97 || byte > 122) { return -1 }
	}
	mut starts := [512]int{}
	mut word_lengths := [512]int{}
	mut word_count := 0
	mut cursor := 0
	for cursor < text_length {
		if unsafe { values[cursor + 1] } == 32 { cursor++; continue }
		starts[word_count] = cursor
		for cursor < text_length && unsafe { values[cursor + 1] } != 32 { cursor++ }
		word_lengths[word_count] = cursor - starts[word_count]
		word_count++
	}
	for index in 1 .. word_count {
		key_start := starts[index]
		key_length := word_lengths[index]
		mut position := index
		for position > 0 && compare_words(values, starts[position - 1], word_lengths[position - 1], key_start, key_length) > 0 {
			starts[position] = starts[position - 1]
			word_lengths[position] = word_lengths[position - 1]
			position--
		}
		starts[position] = key_start
		word_lengths[position] = key_length
	}
	mut output_length := 0
	mut unique_count := 0
	for index in 0 .. word_count {
		if index > 0 && compare_words(values, starts[index - 1], word_lengths[index - 1], starts[index], word_lengths[index]) == 0 { continue }
		if unique_count > 0 { output_length++ }
		output_length += word_lengths[index]
		unique_count++
	}
	if output_length > int(output_capacity) { return -2 }
	mut written := 0
	mut emitted := 0
	for index in 0 .. word_count {
		if index > 0 && compare_words(values, starts[index - 1], word_lengths[index - 1], starts[index], word_lengths[index]) == 0 { continue }
		if emitted > 0 { unsafe { output[written] = 32 }; written++ }
		for byte in 0 .. word_lengths[index] {
			unsafe { output[written] = u8(values[1 + starts[index] + byte]) }
			written++
		}
		emitted++
	}
	return i64(output_length)
}
