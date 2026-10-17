module transposition_rust

const max_keys = 4
const max_key_length = 32
const max_message_length = 256
const max_input_length = 3 + max_keys + max_keys * max_key_length + max_message_length
const max_output_length = 2 * max_message_length - 1

fn is_ascii_letter(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

fn normalize(input []u8, mut output []u8) int {
	mut count := 0
	for byte in input {
		mut ch := byte
		if ch >= 97 && ch <= 122 { ch = ch - 32 }
		if ch >= 65 && ch <= 90 { output[count] = ch; count++ }
	}
	return count
}

fn column_order(key []u8, mut order []int) {
	for index in 0 .. key.len { order[index] = index }
	for index in 1 .. key.len {
		column := order[index]
		mut position := index
		for position > 0 && key[order[position - 1]] > key[column] {
			order[position] = order[position - 1]
			position--
		}
		order[position] = column
	}
}

fn encrypt_round(text []u8, key []u8, mut output []u8) int {
	mut order := []int{len: key.len, init: 0}
	mut columns := []u8{len: text.len, init: 0}
	column_order(key, mut order)
	mut ordered_length := 0
	for rank in 0 .. key.len {
		mut position := order[rank]
		for position < text.len {
			columns[ordered_length] = text[position]
			ordered_length++
			position += key.len
		}
	}
	group_size := (text.len + key.len - 1) / key.len
	mut output_length := 0
	for index in 0 .. ordered_length {
		output[output_length] = columns[index]
		output_length++
		if (index + 1) % group_size == 0 && index + 1 < ordered_length {
			output[output_length] = 32
			output_length++
		}
	}
	return output_length
}

fn decrypt_round(text []u8, key []u8, mut output []u8) int {
	mut order := []int{len: key.len, init: 0}
	mut columns := [max_key_length][max_message_length]u8{}
	mut column_lengths := [max_key_length]int{}
	column_order(key, mut order)
	short_length := text.len / key.len
	longer_columns := text.len % key.len
	mut cursor := 0
	for rank in 0 .. key.len {
		column := order[rank]
		mut column_length := short_length
		if column < longer_columns { column_length++ }
		column_lengths[column] = column_length
		for row in 0 .. column_length { columns[column][row] = text[cursor]; cursor++ }
	}
	mut row_count := short_length
	if longer_columns > 0 { row_count++ }
	mut output_length := 0
	for row in 0 .. row_count {
		for column in 0 .. key.len {
			if row < column_lengths[column] { output[output_length] = columns[column][row]; output_length++ }
		}
	}
	return output_length
}

fn hash_output(text []u8) i64 {
	mut hash := u64(14695981039346656037)
	mut length_bits := u64(text.len)
	for _ in 0 .. 8 { hash = (hash ^ (length_bits & 255)) * u64(1099511628211); length_bits >>= 8 }
	for byte in text {
		mut codepoint := u32(byte)
		for _ in 0 .. 4 { hash = (hash ^ u64(codepoint & 255)) * u64(1099511628211); codepoint >>= 8 }
	}
	return i64(hash & u64(0x7fffffffffffffff))
}

@[export: 'transposition_rust']
pub fn transposition_rust(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		mode := input[0]
		key_count_value := input[1]
		if (mode != 0 && mode != 1) || key_count_value < 1 || key_count_value > max_keys { return -1 }
		key_count := int(key_count_value)
		mut keys := [max_keys][max_key_length]u8{}
		mut key_lengths := [max_keys]int{}
		mut longest_key := 0
		mut cursor := 2
		for key_index in 0 .. key_count {
			if cursor >= int(length) { return -1 }
			key_length_value := input[cursor]
			cursor++
			if key_length_value < 1 || key_length_value > max_key_length { return -1 }
			key_length := int(key_length_value)
			if key_length > int(length) - cursor { return -1 }
			for index in 0 .. key_length {
				value := input[cursor + index]
				if !is_ascii_letter(value) { return -1 }
				mut byte := u8(value)
				if byte >= 97 && byte <= 122 { byte -= 32 }
				keys[key_index][index] = byte
			}
			cursor += key_length
			key_lengths[key_index] = key_length
			if key_length > longest_key { longest_key = key_length }
		}
		if cursor >= int(length) { return -1 }
		message_length_value := input[cursor]
		cursor++
		if message_length_value < 1 || message_length_value > max_message_length { return -1 }
		message_length := int(message_length_value)
		if message_length != int(length) - cursor { return -1 }
		mut message := []u8{len: message_length, init: 0}
		for index in 0 .. message_length {
			value := input[cursor + index]
			if value < 0 || value > 127 { return -1 }
			message[index] = u8(value)
		}
		mut current := []u8{len: max_output_length, init: 0}
		mut filtered := []u8{len: max_message_length, init: 0}
		mut next := []u8{len: max_output_length, init: 0}
		mut current_length := normalize(message, mut current)
		if current_length < longest_key { return -1 }
		for pass in 0 .. key_count {
			key_index := if mode == 0 { pass } else { key_count - 1 - pass }
			filtered_length := normalize(current[..current_length], mut filtered)
			key := keys[key_index][..key_lengths[key_index]]
			mut next_length := 0
			if mode == 0 { next_length = encrypt_round(filtered[..filtered_length], key, mut next) }
			else { next_length = decrypt_round(filtered[..filtered_length], key, mut next) }
			for index in 0 .. next_length { current[index] = next[index] }
			current_length = next_length
		}
		return hash_output(current[..current_length])
	}
}
