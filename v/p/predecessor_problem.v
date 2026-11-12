module predecessor_problem

const max_n = 4096
const max_words = 64
const max_queries = 512
const max_input_length = 1090
const max_output_bytes = 4096

fn find_next(words []u64, n int, key int) i64 {
	first_word := key / 64
	for word in first_word .. words.len {
		first_bit := if word == first_word { key % 64 } else { 0 }
		mut candidates := words[word]
		if first_bit != 0 { candidates &= (u64(0) - 1) << u64(first_bit) }
		if candidates == 0 { continue }
		end_bit := if (word + 1) * 64 < n { 64 } else { n - word * 64 }
		for bit in first_bit .. end_bit {
			if ((candidates >> u64(bit)) & 1) != 0 { return i64(word * 64 + bit) }
		}
	}
	return -1
}

fn find_previous(words []u64, n int, key int) i64 {
	first_word := key / 64
	mut word := first_word + 1
	for word > 0 {
		word--
		valid_bits := if (word + 1) * 64 > n { n - word * 64 } else { 64 }
		requested_end := if word == first_word { key % 64 + 1 } else { valid_bits }
		end_bit := min(requested_end, valid_bits)
		mask := u64(0) - 1
		if end_bit < 64 { mask = (u64(1) << u64(end_bit)) - 1 }
		candidates := words[word] & mask
		if candidates == 0 { continue }
		mut bit := end_bit
		for bit > 0 {
			bit--
			if ((candidates >> u64(bit)) & 1) != 0 { return i64(word * 64 + bit) }
		}
	}
	return -1
}

fn store_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'predecessor_problem']
pub fn predecessor_problem(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	query_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || query_value < 0 || query_value > max_queries { return -1 }
	n := int(n_value)
	queries := int(query_value)
	word_count := (n + 63) / 64
	operation_offset := 2 + word_count
	if int(length) != operation_offset + 2 * queries { return -1 }
	mut words := []u64{len: max_words}
	for word in 0 .. word_count { words[word] = u64(unsafe { input[2 + word] }) }
	tail_bits := n % 64
	if tail_bits != 0 && (words[word_count - 1] >> u64(tail_bits)) != 0 { return -1 }
	for query in 0 .. queries {
		operation := unsafe { input[operation_offset + 2 * query] }
		key := unsafe { input[operation_offset + 2 * query + 1] }
		if operation < 0 || operation > 4 || key < 0 || key >= n_value { return -1 }
	}
	mut answers := []i64{len: max_queries}
	mut answer_count := 0
	for query in 0 .. queries {
		operation := unsafe { input[operation_offset + 2 * query] }
		key := int(unsafe { input[operation_offset + 2 * query + 1] })
		word := key / 64
		mask := u64(1) << u64(key % 64)
		if operation == 0 { words[word] |= mask }
		else if operation == 1 { words[word] &= ~mask }
		else if operation == 2 {
			answers[answer_count] = if words[word] & mask != 0 { 1 } else { 0 }
			answer_count++
		} else if operation == 3 {
			answers[answer_count] = find_next(words[..word_count], n, key)
			answer_count++
		} else {
			answers[answer_count] = find_previous(words[..word_count], n, key)
			answer_count++
		}
	}
	output_bytes := answer_count * 8
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	mut staged := []u8{len: max_output_bytes}
	for index in 0 .. answer_count { store_i64_le(&staged[0], index * 8, answers[index]) }
	for byte in 0 .. output_bytes { unsafe { output[byte] = staged[byte] } }
	return i64(output_bytes)
}
