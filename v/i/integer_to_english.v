module integer_to_english

fn small_word(value int) string {
	return match value {
		1 { 'One' }
		2 { 'Two' }
		3 { 'Three' }
		4 { 'Four' }
		5 { 'Five' }
		6 { 'Six' }
		7 { 'Seven' }
		8 { 'Eight' }
		9 { 'Nine' }
		10 { 'Ten' }
		11 { 'Eleven' }
		12 { 'Twelve' }
		13 { 'Thirteen' }
		14 { 'Fourteen' }
		15 { 'Fifteen' }
		16 { 'Sixteen' }
		17 { 'Seventeen' }
		18 { 'Eighteen' }
		19 { 'Nineteen' }
		20 { 'Twenty' }
		else { '' }
	}
}

fn tens_word(value int) string {
	return match value {
		2 { 'Twenty' }
		3 { 'Thirty' }
		4 { 'Forty' }
		5 { 'Fifty' }
		6 { 'Sixty' }
		7 { 'Seventy' }
		8 { 'Eighty' }
		9 { 'Ninety' }
		else { '' }
	}
}

fn append_text(mut buffer []u8, position_input int, text string) int {
	mut position := position_input
	for index in 0 .. text.len {
		buffer[position] = text[index]
		position++
	}
	return position
}

fn append_word(mut buffer []u8, position_input int, text string) int {
	mut position := position_input
	if position != 0 {
		buffer[position] = 32
		position++
	}
	return append_text(mut buffer, position, text)
}

fn append_small(mut buffer []u8, position int, value int) int {
	word := small_word(value)
	if word.len == 0 { return position }
	return append_word(mut buffer, position, word)
}

fn append_group(mut buffer []u8, position_input int, value_input int) int {
	mut position := position_input
	mut value := value_input
	if value >= 100 {
		position = append_small(mut buffer, position, value / 100)
		position = append_word(mut buffer, position, 'Hundred')
		value %= 100
	}
	if value <= 20 {
		return append_small(mut buffer, position, value)
	}
	position = append_word(mut buffer, position, tens_word(value / 10))
	if value % 10 != 0 { position = append_small(mut buffer, position, value % 10) }
	return position
}

fn append_scale(mut buffer []u8, position int, scale int) int {
	word := match scale {
		1 { 'Thousand' }
		2 { 'Million' }
		3 { 'Billion' }
		else { '' }
	}
	if word.len == 0 { return position }
	return append_word(mut buffer, position, word)
}

@[export: 'integer_to_english']
pub fn integer_to_english(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 1 || unsafe { input == nil } { return -1 }
	unsafe {
		value := input[0]
		if value < -2147483648 || value > 2147483647 { return -1 }
		mut buffer := [128]u8{}
		mut position := 0
		if value == 0 {
			position = append_word(mut buffer[..], position, 'Zero')
		} else if value > 0 {
			mut groups := [4]int{}
			mut remaining := int(value)
			mut count := 0
			for remaining != 0 {
				groups[count] = remaining % 1000
				count++
				remaining /= 1000
			}
			for count > 0 {
				count--
				if groups[count] != 0 {
					position = append_group(mut buffer[..], position, groups[count])
					if count != 0 { position = append_scale(mut buffer[..], position, count) }
				}
			}
		}
		if position > int(output_capacity) || (position != 0 && output == nil) { return -2 }
		for index in 0 .. position { output[index] = buffer[index] }
		return i64(position)
	}
}
