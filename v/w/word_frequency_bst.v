module word_frequency_bst

const max_input_bytes = 256
const max_token_bytes = 45
const max_unique_words = 128
const max_output_bytes = 896

struct WordNode {
	word [46]u8
	word_length int
	frequency u64
	left int
	right int
}

fn ascii_alpha(value int) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@[export: 'word_frequency_bst']
pub fn word_frequency_bst(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_bytes + 2 { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_input_bytes { return -1 }
		text_length := int(n_value)
		if length != usize(text_length + 1) { return -1 }
		for i in 0 .. text_length {
			if input[i + 1] < 0 || input[i + 1] > 127 { return -1 }
		}

		mut nodes := [max_unique_words]WordNode{}
		for i in 0 .. max_unique_words {
			nodes[i].left = -1
			nodes[i].right = -1
		}
		mut used := 0
		mut root := -1
		mut token := [max_token_bytes + 1]u8{}
		mut token_length := 0
		for position in 0 .. text_length + 1 {
			mut byte := -1
			if position < text_length { byte = int(input[position + 1]) }
			if ascii_alpha(byte) {
				if token_length >= max_token_bytes { return -1 }
				if byte >= 65 && byte <= 90 { byte += 32 }
				token[token_length] = u8(byte)
				token_length++
			} else if (byte == 39 || byte == 45) && token_length > 0 && ascii_alpha(int(token[token_length - 1])) {
				if token_length >= max_token_bytes { return -1 }
				token[token_length] = u8(byte)
				token_length++
			} else {
				if token_length > 0 {
					if token[token_length - 1] == 45 { token_length-- }
					if token_length > 0 {
						if root < 0 {
							if used >= max_unique_words { return -1 }
							root = used
							for j in 0 .. token_length { nodes[used].word[j] = token[j] }
							nodes[used].word[token_length] = 0
							nodes[used].word_length = token_length
							nodes[used].frequency = 1
							used++
						} else {
							mut current := root
							for {
								mut common := token_length
								if nodes[current].word_length < common { common = nodes[current].word_length }
								mut order := 0
								for j in 0 .. common {
									if token[j] < nodes[current].word[j] { order = -1; break }
									if token[j] > nodes[current].word[j] { order = 1; break }
								}
								if order == 0 {
									if token_length < nodes[current].word_length { order = -1 }
									if token_length > nodes[current].word_length { order = 1 }
								}
								if order == 0 { nodes[current].frequency++; break }
								mut child := if order < 0 { nodes[current].left } else { nodes[current].right }
								if child < 0 {
									if used >= max_unique_words { return -1 }
									child = used
									for j in 0 .. token_length { nodes[used].word[j] = token[j] }
									nodes[used].word[token_length] = 0
									nodes[used].word_length = token_length
									nodes[used].frequency = 1
									nodes[used].left = -1
									nodes[used].right = -1
									if order < 0 { nodes[current].left = child } else { nodes[current].right = child }
									used++
									break
								}
								current = child
							}
						}
					}
					token_length = 0
				}
			}
		}

		mut result := [max_output_bytes]u8{}
		mut stack := [max_unique_words]int{}
		mut top := 0
		mut written := 0
		mut current := root
		for current >= 0 || top > 0 {
			for current >= 0 {
				if top >= max_unique_words { return -1 }
				stack[top] = current
				top++
				current = nodes[current].left
			}
			top--
			current = stack[top]
			for i in 0 .. nodes[current].word_length {
				if written >= max_output_bytes { return -1 }
				result[written] = nodes[current].word[i]
				written++
			}
			if written + 1 >= max_output_bytes { return -1 }
			result[written] = 9
			written++
			mut reversed := [20]u8{}
			mut digits := 0
			mut frequency := nodes[current].frequency
			for {
				reversed[digits] = u8(48 + int(frequency % 10))
				digits++
				frequency /= 10
				if frequency == 0 { break }
			}
			for digits > 0 {
				digits--
				if written >= max_output_bytes { return -1 }
				result[written] = reversed[digits]
				written++
			}
			if written >= max_output_bytes { return -1 }
			result[written] = 10
			written++
			current = nodes[current].right
		}

		if output == nil || capacity < usize(written) { return -2 }
		for i in 0 .. written { output[i] = result[i] }
		return i64(written)
	}
}
