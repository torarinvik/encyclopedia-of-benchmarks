module anagram_dictionary_search

const max_words = 16
const max_word_length = 16

fn is_anagram(input &i64, query_length int, word_offset int, word_length int) bool {
	if query_length != word_length { return false }
	mut counts := [26]int{}
	unsafe {
		for index in 0 .. query_length {
			counts[int(input[2 + index]) - 97]++
			counts[int(input[word_offset + index]) - 97]--
		}
	}
	for count in counts { if count != 0 { return false } }
	return true
}

fn put_byte(mut output &u8, capacity usize, mut position &int, value u8) bool {
	if usize(position) >= capacity { return false }
	unsafe { output[position] = value }
	position++
	return true
}

@[export: 'anagram_dictionary_search']
pub fn anagram_dictionary_search(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_words || input[1] < 0 || input[1] > max_word_length { return -1 }
	}
	unsafe {
		word_count := int(input[0])
		query_length := int(input[1])
		if 2 + query_length > int(length) { return -1 }
		for index in 0 .. query_length { if input[2 + index] < 97 || input[2 + index] > 122 { return -1 } }
		if output == nil { return -2 }
		mut offset := 2 + query_length
		mut position := 0
		for _ in 0 .. word_count {
			if offset >= int(length) || input[offset] < 1 || input[offset] > max_word_length { return -1 }
			word_length := int(input[offset]); offset++
			if offset + word_length > int(length) { return -1 }
			for index in 0 .. word_length { if input[offset + index] < 97 || input[offset + index] > 122 { return -1 } }
			if is_anagram(input, query_length, offset, word_length) {
				for index in 0 .. word_length {
					if !put_byte(mut output, output_capacity, mut position, u8(input[offset + index])) { return -2 }
				}
				if !put_byte(mut output, output_capacity, mut position, 10) { return -2 }
			}
			offset += word_length
		}
		if offset != int(length) { return -1 }
		if !put_byte(mut output, output_capacity, mut position, 0) { return -2 }
		return i64(position)
	}
}
