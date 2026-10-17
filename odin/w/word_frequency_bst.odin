package word_frequency_bst

import "core:c"

MAX_INPUT_BYTES :: 256
MAX_TOKEN_BYTES :: 45
MAX_UNIQUE_WORDS :: 128
MAX_OUTPUT_BYTES :: 896

Word_Node :: struct {
	word: [46]u8,
	word_length: int,
	frequency: u64,
	left: int,
	right: int,
}

ascii_alpha :: proc(value: int) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@(export, link_name="word_frequency_bst")
word_frequency_bst :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_BYTES + 2) do return -1
	n := input[0]
	if n < 0 || n > MAX_INPUT_BYTES do return -1
	text_length := int(n)
	if length != c.size_t(text_length + 1) do return -1
	for i := 0; i < text_length; i += 1 {
		if input[i + 1] < 0 || input[i + 1] > 127 do return -1
	}

	var nodes: [MAX_UNIQUE_WORDS]Word_Node
	for i := 0; i < MAX_UNIQUE_WORDS; i += 1 {
		nodes[i].left = -1
		nodes[i].right = -1
	}
	used := 0
	root := -1
	var token: [MAX_TOKEN_BYTES + 1]u8
	token_length := 0
	for position := 0; position <= text_length; position += 1 {
		byte := -1
		if position < text_length { byte = int(input[position + 1]) }
		if ascii_alpha(byte) {
			if token_length >= MAX_TOKEN_BYTES do return -1
			if byte >= 65 && byte <= 90 { byte += 32 }
			token[token_length] = u8(byte)
			token_length += 1
		} else if (byte == 39 || byte == 45) && token_length > 0 && ascii_alpha(int(token[token_length - 1])) {
			if token_length >= MAX_TOKEN_BYTES do return -1
			token[token_length] = u8(byte)
			token_length += 1
		} else {
			if token_length > 0 {
				if token[token_length - 1] == 45 { token_length -= 1 }
				if token_length > 0 {
					if root < 0 {
						if used >= MAX_UNIQUE_WORDS do return -1
					root = used
					for j := 0; j < token_length; j += 1 { nodes[used].word[j] = token[j] }
					nodes[used].word[token_length] = 0
					nodes[used].word_length = token_length
					nodes[used].frequency = 1
					used += 1
				} else {
					current := root
					for {
						common := token_length
						if nodes[current].word_length < common { common = nodes[current].word_length }
						order := 0
						for j := 0; j < common; j += 1 {
							if token[j] < nodes[current].word[j] { order = -1; break }
							if token[j] > nodes[current].word[j] { order = 1; break }
						}
						if order == 0 {
							if token_length < nodes[current].word_length { order = -1 }
							if token_length > nodes[current].word_length { order = 1 }
						}
						if order == 0 { nodes[current].frequency += 1; break }
						child := if order < 0 { nodes[current].left } else { nodes[current].right }
						if child < 0 {
							if used >= MAX_UNIQUE_WORDS do return -1
							child = used
							for j := 0; j < token_length; j += 1 { nodes[used].word[j] = token[j] }
							nodes[used].word[token_length] = 0
							nodes[used].word_length = token_length
							nodes[used].frequency = 1
							nodes[used].left = -1
							nodes[used].right = -1
							if order < 0 { nodes[current].left = child } else { nodes[current].right = child }
							used += 1
							break
						}
						current = child
					}
				}
			}
			token_length = 0
		}
	}

	var result: [MAX_OUTPUT_BYTES]u8
	var stack: [MAX_UNIQUE_WORDS]int
	top := 0
	written := 0
	current := root
	for current >= 0 || top > 0 {
		for current >= 0 {
			if top >= MAX_UNIQUE_WORDS do return -1
			stack[top] = current
			top += 1
			current = nodes[current].left
		}
		top -= 1
		current = stack[top]
		for i := 0; i < nodes[current].word_length; i += 1 {
			if written >= MAX_OUTPUT_BYTES do return -1
			result[written] = nodes[current].word[i]
			written += 1
		}
		if written+1 >= MAX_OUTPUT_BYTES do return -1
		result[written] = 9
		written += 1
		var reversed: [20]u8
		digits := 0
		frequency := nodes[current].frequency
		for {
			reversed[digits] = u8(48 + frequency%10)
			digits += 1
			frequency /= 10
			if frequency == 0 do break
		}
		for digits > 0 {
			digits -= 1
			if written >= MAX_OUTPUT_BYTES do return -1
			result[written] = reversed[digits]
			written += 1
		}
		if written >= MAX_OUTPUT_BYTES do return -1
		result[written] = 10
		written += 1
		current = nodes[current].right
	}

	if output == nil || capacity < c.size_t(written) do return -2
	for i := 0; i < written; i += 1 { output[i] = result[i] }
	return i64(written)
}
