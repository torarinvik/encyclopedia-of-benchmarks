const max_text = 256
const max_key = 32

@[export: 'columnar_transposition']
pub fn columnar_transposition(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if isnil(input) || length < 3 { return -1 }
	operation := unsafe { input[0] }
	text_value := unsafe { input[1] }
	raw_key_value := unsafe { input[2] }
	if (operation != 0 && operation != 1) || text_value < 0 || text_value > max_text || raw_key_value < 1 || raw_key_value > max_key { return -1 }
	text_length := int(text_value)
	raw_key_length := int(raw_key_value)
	if length != usize(3 + text_length + raw_key_length) { return -1 }
	mut key := []u8{len: max_key, init: 0}
	mut order := []int{len: max_key, init: 0}
	mut key_length := 0
	for index in 0 .. text_length { if unsafe { input[3 + index] } < 0 || unsafe { input[3 + index] } > 127 { return -1 } }
	for index in 0 .. raw_key_length {
		value := unsafe { input[3 + text_length + index] }
		if value < 0 || value > 127 { return -1 }
		if value >= 65 && value <= 90 { key[key_length] = u8(value); key_length++
		} else if value >= 97 && value <= 122 { key[key_length] = u8(value - 32); key_length++ }
	}
	if key_length == 0 { return -1 }
	for index in 0 .. key_length {
		order[index] = index
		mut position := index
		for position > 0 && key[order[position - 1]] > key[index] {
			order[position] = order[position - 1]
			position--
		}
		order[position] = index
	}
	if text_length == 0 { return 0 }
	if isnil(output) || capacity < usize(text_length) { return -2 }
	rows := (text_length + key_length - 1) / key_length
	if operation == 0 {
		mut written := 0
		for rank in 0 .. key_length {
			column := order[rank]
			for row in 0 .. rows {
				index := row * key_length + column
				if index < text_length { unsafe { output[written] = u8(input[3 + index]) }; written++ }
			}
		}
		return i64(written)
	}
	mut column_data := []u8{len: max_key * max_text, init: 0}
	mut column_lengths := []int{len: max_key, init: 0}
	mut offset := 0
	short_columns := text_length % key_length
	for column in 0 .. key_length {
		column_lengths[column] = rows
		if short_columns != 0 && column >= short_columns { column_lengths[column] = rows - 1 }
	}
	for rank in 0 .. key_length {
		column := order[rank]
		for row in 0 .. column_lengths[column] {
			column_data[column * max_text + row] = u8(unsafe { input[3 + offset] })
			offset++
		}
	}
	mut written := 0
	for row in 0 .. rows {
		for column in 0 .. key_length {
			if row < column_lengths[column] { unsafe { output[written] = column_data[column * max_text + row] }; written++ }
		}
	}
	return i64(written)
}
