module addition_of_big_integers

@[export: 'addition_of_big_integers']
pub fn addition_of_big_integers(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > 68 { return -1 }
	unsafe {
		raw_a, raw_b := input[0], input[1]
		if raw_a < 1 || raw_a > 33 || raw_b < 1 || raw_b > 33 { return -1 }
		len_a, len_b := int(raw_a), int(raw_b)
		if int(length) != 2 + len_a + len_b { return -1 }
		mut starts := [2]int{2, 2 + len_a}
		mut counts := [2]int{len: 2, init: 0}
		mut negative := [2]bool{len: 2, init: false}
		text_lengths := [2]int{len_a, len_b}
		for operand in 0 .. 2 {
			if text_lengths[operand] < 1 || text_lengths[operand] > 33 { return -1 }
			negative[operand] = input[starts[operand]] == 45
			if negative[operand] { starts[operand]++ }
			counts[operand] = text_lengths[operand] - (if negative[operand] { 1 } else { 0 })
			if counts[operand] < 1 || counts[operand] > 32 { return -1 }
			for index in 0 .. counts[operand] {
				byte := input[starts[operand] + index]
				if byte < 48 || byte > 57 || (index == 0 && counts[operand] > 1 && byte == 48) { return -1 }
			}
			if negative[operand] && counts[operand] == 1 && input[starts[operand]] == 48 { return -1 }
		}

		mut reversed := []u8{len: 33, init: 0}
		mut digits := 0
		mut negative_result := false
		if negative[0] == negative[1] {
			negative_result = negative[0]
			mut width := counts[0]
			if counts[1] > width { width = counts[1] }
			mut carry := 0
			for offset in 0 .. width {
				da := if offset < counts[0] { int(input[starts[0] + counts[0] - 1 - offset] - 48) } else { 0 }
				db := if offset < counts[1] { int(input[starts[1] + counts[1] - 1 - offset] - 48) } else { 0 }
				total := da + db + carry
				reversed[digits] = u8(total % 10)
				digits++
				carry = total / 10
			}
			if carry != 0 { reversed[digits] = u8(carry); digits++ }
		} else {
			mut order := 0
			if counts[0] > counts[1] { order = 1 } else if counts[0] < counts[1] { order = -1 } else {
				for index in 0 .. counts[0] {
					if order == 0 {
						da, db := input[starts[0] + index], input[starts[1] + index]
						if da > db { order = 1 } else if da < db { order = -1 }
					}
				}
			}
			if order == 0 {
				reversed[0] = 0
				digits = 1
			} else {
				big, small := 0, 1
				if order < 0 { big, small = 1, 0 }
				negative_result = negative[big]
				mut borrow := 0
				for offset in 0 .. counts[big] {
					da := int(input[starts[big] + counts[big] - 1 - offset] - 48)
					db := if offset < counts[small] { int(input[starts[small] + counts[small] - 1 - offset] - 48) } else { 0 }
					digit := da - db - borrow
					borrow = if digit < 0 { 1 } else { 0 }
					reversed[digits] = u8(if digit < 0 { digit + 10 } else { digit })
					digits++
				}
				for digits > 1 && reversed[digits - 1] == 0 { digits-- }
			}
		}

		output_length := digits + (if negative_result { 1 } else { 0 })
		if output == nil || capacity < output_length { return -2 }
		mut cursor := 0
		if negative_result { output[cursor] = 45; cursor++ }
		for index in 0 .. digits {
			output[cursor] = u8(48 + int(reversed[digits - 1 - index]))
			cursor++
		}
		return i64(output_length)
	}
}
