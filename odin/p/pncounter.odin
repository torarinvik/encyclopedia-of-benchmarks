package pncounter

import "core:c"

MAX_NODES :: 16
MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 5 + MAX_OPERATIONS
MAX_OUTPUT_WORDS :: 2 * MAX_OPERATIONS
PAIR_LEFT :: [6]int{0, 0, 1, 1, 2, 2}
PAIR_RIGHT :: [6]int{1, 2, 0, 2, 0, 1}

append :: proc(words: ^[MAX_OUTPUT_WORDS]i64, count: ^c.size_t, value: i64) {
	words[count^] = value
	count^ += 1
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> u64(8*byte)) & 255)
	}
}

@(export)
pncounter :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_NODES ||
		input[4] < 0 || input[4] > MAX_OPERATIONS do return -1

	node_count := int(input[0])
	ids: [3]int
	for counter := 0; counter < 3; counter += 1 {
		if input[1+counter] < 0 || input[1+counter] >= input[0] do return -1
		ids[counter] = int(input[1+counter])
	}
	operation_count := int(input[4])
	if length != 5 + operation_count do return -1

	var positive: [3][MAX_NODES]i64
	var negative: [3][MAX_NODES]i64
	var words: [MAX_OUTPUT_WORDS]i64
	word_count: c.size_t = 0
	position: c.size_t = 5

	for _ in 0..<operation_count {
		opcode := input[position]
		position += 1
		if opcode < 0 || opcode > 20 do return -1
		if opcode < 6 {
			counter := int(opcode / 2)
			if opcode % 2 == 0 do positive[counter][ids[counter]] += 1
			else do negative[counter][ids[counter]] += 1
			append(&words, &word_count, opcode)
		} else if opcode < 9 {
			counter := int(opcode - 6)
			value: i64 = 0
			for node := 0; node < node_count; node += 1 {
				value += positive[counter][node] - negative[counter][node]
			}
			append(&words, &word_count, opcode)
			append(&words, &word_count, value)
		} else if opcode < 15 {
			pair := int(opcode - 9)
			target, source := PAIR_LEFT[pair], PAIR_RIGHT[pair]
			for node := 0; node < node_count; node += 1 {
				positive[target][node] = max(positive[target][node], positive[source][node])
				negative[target][node] = max(negative[target][node], negative[source][node])
			}
			append(&words, &word_count, opcode)
		} else {
			pair := int(opcode - 15)
			left, right := PAIR_LEFT[pair], PAIR_RIGHT[pair]
			result: i64 = 1
			for node := 0; node < node_count; node += 1 {
				if positive[left][node] > positive[right][node] &&
					negative[left][node] > negative[right][node] {
					result = 0
					break
				}
			}
			append(&words, &word_count, opcode)
			append(&words, &word_count, result)
		}
	}

	output_length := word_count * 8
	if output == nil || output_capacity < output_length do return -2
	for i: c.size_t = 0; i < word_count; i += 1 {
		put_i64_le(output, int(i*8), words[i])
	}
	return i64(output_length)
}
