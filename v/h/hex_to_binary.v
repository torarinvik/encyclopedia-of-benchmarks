module hex_to_binary

fn hex_value(value i64) int {
	if value >= 48 && value <= 57 { return int(value - 48) }
	if value >= 65 && value <= 70 { return int(value - 65 + 10) }
	if value >= 97 && value <= 102 { return int(value - 97 + 10) }
	return -1
}

@[export: 'hex_to_binary']
pub fn hex_to_binary(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if length > 256 || (length != 0 && unsafe { values == nil }) { return -1 }
	unsafe {
		for index in 0 .. int(length) {
			if hex_value(values[index]) < 0 { return -1 }
		}

		required := int(length) * 4
		if output == nil || capacity < usize(required) { return -2 }
		for index in 0 .. int(length) {
			digit := hex_value(values[index])
			for bit in 0 .. 4 {
				output[index * 4 + bit] = if ((digit >> (3 - bit)) & 1) == 1 { u8(`1`) } else { u8(`0`) }
			}
		}
		return i64(required)
	}
}
