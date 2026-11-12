package predecessor_problem

import "core:c"

MAX_N :: 4096
MAX_WORDS :: 64
MAX_QUERIES :: 512
MAX_INPUT_LENGTH :: 1090
MAX_OUTPUT_BYTES :: 4096

find_next :: proc(words: []u64, n, key: int) -> i64 {
	first_word := key / 64
	for word := first_word; word < len(words); word += 1 {
		first_bit := 0
		if word == first_word do first_bit = key % 64
		candidates := words[word]
		if first_bit != 0 do candidates &= (u64(0) - 1) << u64(first_bit)
		if candidates == 0 do continue
		end_bit := 64
		if (word + 1) * 64 >= n do end_bit = n - word * 64
		for bit := first_bit; bit < end_bit; bit += 1 {
			if ((candidates >> u64(bit)) & 1) != 0 do return i64(word*64 + bit)
		}
	}
	return -1
}

find_previous :: proc(words: []u64, n, key: int) -> i64 {
	first_word := key / 64
	word := first_word + 1
	for word > 0 {
		word -= 1
		valid_bits := 64
		if (word + 1) * 64 > n do valid_bits = n - word*64
		requested_end := valid_bits
		if word == first_word do requested_end = key%64 + 1
		end_bit := min(requested_end, valid_bits)
		mask := u64(0) - 1
		if end_bit < 64 do mask = (u64(1) << u64(end_bit)) - 1
		candidates := words[word] & mask
		if candidates != 0 {
			bit := end_bit
			for bit > 0 {
				bit -= 1
				if ((candidates >> u64(bit)) & 1) != 0 do return i64(word*64 + bit)
			}
		}
	}
	return -1
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
predecessor_problem :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	n_value, query_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || query_value < 0 || query_value > MAX_QUERIES do return -1
	n, queries := int(n_value), int(query_value)
	word_count := (n + 63) / 64
	operation_offset := 2 + word_count
	if int(length) != operation_offset + 2*queries do return -1
	words: [MAX_WORDS]u64
	for word := 0; word < word_count; word += 1 do words[word] = u64(input[2+word])
	tail_bits := n % 64
	if tail_bits != 0 && (words[word_count-1] >> u64(tail_bits)) != 0 do return -1
	for query := 0; query < queries; query += 1 {
		operation := input[operation_offset+2*query]
		key := input[operation_offset+2*query+1]
		if operation < 0 || operation > 4 || key < 0 || key >= n_value do return -1
	}
	answers: [MAX_QUERIES]i64
	answer_count := 0
	for query := 0; query < queries; query += 1 {
		operation := input[operation_offset+2*query]
		key := int(input[operation_offset+2*query+1])
		word := key / 64
		mask := u64(1) << u64(key%64)
		if operation == 0 do words[word] |= mask
		else if operation == 1 do words[word] &= ~mask
		else if operation == 2 {
			answers[answer_count] = i64((words[word] & mask) != 0)
			answer_count += 1
		} else if operation == 3 {
			answers[answer_count] = find_next(words[:word_count], n, key)
			answer_count += 1
		} else {
			answers[answer_count] = find_previous(words[:word_count], n, key)
			answer_count += 1
		}
	}
	output_bytes := answer_count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for index := 0; index < answer_count; index += 1 do store_i64_le(&staged[0], index*8, answers[index])
	for byte := 0; byte < output_bytes; byte += 1 do output[byte] = staged[byte]
	return i64(output_bytes)
}
