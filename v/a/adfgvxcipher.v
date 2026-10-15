module adfgvxcipher

const max_plaintext = 256
const max_ciphertext = 512
const max_key = 16
const max_rows = 512
const labels = "ADFGVX"
const square = "NA1C3H8TB2OME5WRPD4F6G7I9J0KLQSUVXYZ"

fn polybius_cell(value u8) int {
	for cell := 0; cell < 36; cell++ {
		if square[cell] == value { return cell }
	}
	return -1
}

fn label_index(value u8) int {
	for index := 0; index < 6; index++ {
		if labels[index] == value { return index }
	}
	return -1
}

@[export: 'adfgvxcipher']
pub fn adfgvxcipher(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length < 3 { return -1 }
	mode := unsafe { values[0] }
	text_length_value := unsafe { values[1] }
	key_length_value := unsafe { values[2] }
	if (mode != 0 && mode != 1) || text_length_value < 0 || key_length_value < 1 || key_length_value > max_key { return -1 }
	text_length := int(text_length_value)
	key_length := int(key_length_value)
	if (mode == 0 && text_length > max_plaintext) || (mode == 1 && text_length > max_ciphertext) ||
		length != usize(3 + text_length + key_length) { return -1 }
	for index := 0; index < text_length; index++ {
		value := unsafe { values[3 + index] }
		if value < 0 || value > 127 { return -1 }
		if mode == 1 && label_index(u8(value)) < 0 { return -1 }
	}
	if mode == 1 && text_length % 2 != 0 { return -1 }
	key_start := 3 + text_length
	for index := 0; index < key_length; index++ {
		value := unsafe { values[key_start + index] }
		if value < 65 || value > 90 { return -1 }
		for previous := 0; previous < index; previous++ {
			previous_value := unsafe { values[key_start + previous] }
			if value == previous_value { return -1 }
		}
	}
	mut order := []int{len: key_length, init: 0}
	for index := 0; index < key_length; index++ { order[index] = index }
	for index := 1; index < key_length; index++ {
		current := order[index]
		mut position := index
		for position > 0 {
			previous_value := unsafe { values[key_start + order[position - 1]] }
			current_value := unsafe { values[key_start + current] }
			if previous_value <= current_value { break }
			order[position] = order[position - 1]
			position--
		}
		order[position] = current
	}

	mut result := []u8{len: max_ciphertext, init: 0}
	mut result_length := 0
	if mode == 0 {
		mut fractionated := []u8{len: max_ciphertext, init: 0}
		mut fractionated_length := 0
		for index := 0; index < text_length; index++ {
			mut value := u8(unsafe { values[3 + index] })
			if value >= u8(`a`) && value <= u8(`z`) { value -= 32 }
			if !((value >= u8(`A`) && value <= u8(`Z`)) || (value >= u8(`0`) && value <= u8(`9`))) { continue }
			cell := polybius_cell(value)
			if cell < 0 { return -1 }
			fractionated[fractionated_length] = labels[cell / 6]
			fractionated[fractionated_length + 1] = labels[cell % 6]
			fractionated_length += 2
		}
		rows := (fractionated_length + key_length - 1) / key_length
		mut table := []u8{len: max_rows * max_key, init: u8(95)}
		for index := 0; index < fractionated_length; index++ {
			table[(index / key_length) * max_key + index % key_length] = fractionated[index]
		}
		for order_index := 0; order_index < key_length; order_index++ {
			column := order[order_index]
			for row := 0; row < rows; row++ {
				value := table[row * max_key + column]
				if value != u8(95) { result[result_length] = value; result_length++ }
			}
		}
	} else {
		rows := (text_length + key_length - 1) / key_length
		mut table := []u8{len: max_rows * max_key, init: 0}
		mut source_index := 0
		for order_index := 0; order_index < key_length; order_index++ {
			column := order[order_index]
			for row := 0; row < rows; row++ {
				if source_index < text_length {
					table[row * max_key + column] = u8(unsafe { values[3 + source_index] })
					source_index++
				} else { table[row * max_key + column] = u8(95) }
			}
		}
		mut fractionated := []u8{len: max_ciphertext, init: 0}
		mut fractionated_length := 0
		for row := 0; row < rows; row++ {
			for column := 0; column < key_length; column++ {
				value := table[row * max_key + column]
				if value != u8(95) { fractionated[fractionated_length] = value; fractionated_length++ }
			}
		}
		for index := 0; index < fractionated_length; index += 2 {
			row := label_index(fractionated[index])
			column := label_index(fractionated[index + 1])
			if row < 0 || column < 0 { return -1 }
			result[result_length] = square[row * 6 + column]
			result_length++
		}
	}
	if output_capacity < usize(result_length) { return -2 }
	unsafe {
		for index := 0; index < result_length; index++ { output[index] = result[index] }
	}
	return i64(result_length)
}
