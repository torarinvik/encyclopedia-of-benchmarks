module maskwords

const max_text_bytes = 512
const max_mask_bytes = 16
const max_parseable_input_length = 531
const max_output_bytes = 1447

fn is_word(value u8) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) ||
		(value >= 48 && value <= 57) || value == 95
}

fn equals_word(token []u8, word string) bool {
	if token.len != word.len { return false }
	for i in 0 .. word.len {
		if token[i] != word[i] { return false }
	}
	return true
}

fn is_normalized_target(token []u8) bool {
	return equals_word(token, 'birds') || equals_word(token, 'BIRDS') ||
		equals_word(token, 'Birds') || equals_word(token, 'market') ||
		equals_word(token, 'MARKET') || equals_word(token, 'Market') ||
		equals_word(token, 'street') || equals_word(token, 'STREET') ||
		equals_word(token, 'Street')
}

fn match_length(text []u8, start int, end int, position int) int {
	mut matched := 0
	if position + 5 <= end && equals_word(text[position..position + 5], 'birds') {
		matched = 5
	} else if position + 6 <= end && (equals_word(text[position..position + 6], 'market') ||
		equals_word(text[position..position + 6], 'street')) {
		matched = 6
	}
	if matched == 0 || (position > start && is_word(text[position - 1])) ||
		(position + matched < end && is_word(text[position + matched])) {
		return 0
	}
	return matched
}

fn append_token(text []u8, start int, end int, mask []u8, mut output []u8, written_value int) int {
	mut written := written_value
	if is_normalized_target(text[start..end]) {
		for byte in mask {
			output[written] = byte
			written++
		}
		return written
	}
	mut position := start
	for position < end {
		matched := match_length(text, start, end, position)
		if matched != 0 {
			for byte in mask {
				output[written] = byte
				written++
			}
			position += matched
		} else {
			if text[position] != 10 {
				output[written] = text[position]
				written++
			}
			position++
		}
	}
	return written
}

@[export: 'maskwords']
pub fn maskwords(values &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_parseable_input_length {
		return -1
	}
	unsafe {
		if values[0] < 0 || values[0] > max_text_bytes { return -1 }
		text_length := int(values[0])
		mask_length_index := 1 + text_length
		if mask_length_index >= int(length) || values[mask_length_index] < 0 ||
			values[mask_length_index] > max_mask_bytes { return -1 }
		mask_length := int(values[mask_length_index])
		if int(length) != mask_length_index + 1 + mask_length { return -1 }

		mut text_storage := [max_text_bytes]u8{}
		mut mask_storage := [max_mask_bytes]u8{}
		for i in 0 .. text_length {
			value := values[1 + i]
			if value < 1 || value > 127 { return -1 }
			text_storage[i] = u8(value)
		}
		for i in 0 .. mask_length {
			value := values[mask_length_index + 1 + i]
			if value < 32 || value > 126 || value == 92 { return -1 }
			mask_storage[i] = u8(value)
		}
		text := text_storage[..text_length]
		mask := mask_storage[..mask_length]
		mut scratch := [max_output_bytes]u8{}
		mut scratch_slice := scratch[..]
		mut written := 0
		mut start := 0
		mut have_token := false
		for i in 0 .. text_length {
			if text[i] == 32 {
				if have_token {
					scratch_slice[written] = 32
					written++
				}
				written = append_token(text, start, i, mask, mut scratch_slice, written)
				have_token = true
				start = i + 1
			}
		}
		if start < text_length {
			if have_token {
				scratch_slice[written] = 32
				written++
			}
			written = append_token(text, start, text_length, mask, mut scratch_slice, written)
		}
		if written > max_output_bytes { return -1 }
		if capacity < usize(written) || (written != 0 && output == nil) { return -2 }
		for i in 0 .. written { output[i] = scratch_slice[i] }
		return i64(written)
	}
}
