module fizz_buzz

fn token_length(value i64) usize {
	if value % 15 == 0 { return 8 }
	if value % 3 == 0 || value % 5 == 0 { return 4 }
	if value >= 100 { return 3 }
	if value >= 10 { return 2 }
	return 1
}

fn append_number(value_value i64, output &u8, position_value usize) usize {
	mut value := value_value
	mut position := position_value
	unsafe {
		if value >= 100 {
			output[position] = u8(48 + value / 100)
			position++
			value %= 100
			output[position] = u8(48 + value / 10)
			position++
			output[position] = u8(48 + value % 10)
			position++
		} else if value >= 10 {
			output[position] = u8(48 + value / 10)
			position++
			output[position] = u8(48 + value % 10)
			position++
		} else {
			output[position] = u8(48 + value)
			position++
		}
	}
	return position
}

@[export: 'fizz_buzz']
pub fn fizz_buzz(value i64, output &u8, output_capacity usize) i64 {
	if value < 1 || value > 512 { return -1 }
	mut width := usize(0)
	for current := i64(1); current <= value; current++ { width += token_length(current) + 1 }
	if unsafe { output == nil } || output_capacity < width { return -2 }
	mut position := usize(0)
	unsafe {
		for current := i64(1); current <= value; current++ {
			if current % 15 == 0 {
				output[position] = u8('F'); output[position + 1] = u8('i'); output[position + 2] = u8('z'); output[position + 3] = u8('z')
				output[position + 4] = u8('B'); output[position + 5] = u8('u'); output[position + 6] = u8('z'); output[position + 7] = u8('z')
				position += 8
			} else if current % 3 == 0 {
				output[position] = u8('F'); output[position + 1] = u8('i'); output[position + 2] = u8('z'); output[position + 3] = u8('z')
				position += 4
			} else if current % 5 == 0 {
				output[position] = u8('B'); output[position + 1] = u8('u'); output[position + 2] = u8('z'); output[position + 3] = u8('z')
				position += 4
			} else {
				position = append_number(current, output, position)
			}
			output[position] = u8(' ')
			position++
		}
	}
	return i64(position)
}
