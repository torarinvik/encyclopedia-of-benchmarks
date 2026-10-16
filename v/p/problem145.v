module problem145

fn count_reversible(remaining i64, carry_in i64, mut digits [9]i64, length i64) i64 {
	if remaining == 0 {
		if digits[0] == 0 || digits[int(length - 1)] == 0 { return 0 }
		mut carry := carry_in
		mut i := length / 2 - 1
		for i >= 0 {
			carry += digits[int(i)] + digits[int(length - i - 1)]
			if carry % 2 == 0 { return 0 }
			carry /= 10
			i--
		}
		return 1
	}
	if remaining == 1 {
		if carry_in % 2 == 0 { return 0 }
		mut result := i64(0)
		for digit in 0 .. 10 {
			digits[int(length / 2)] = i64(digit)
			result += count_reversible(0, (carry_in + 2 * i64(digit)) / 10, mut digits, length)
		}
		return result
	}
	mut result := i64(0)
	right_index := int((length + remaining) / 2 - 1)
	left_index := int((length - remaining) / 2)
	for digit1 in 0 .. 10 {
		digits[right_index] = i64(digit1)
		parity := if (carry_in + i64(digit1)) % 2 == 0 { 1 } else { 0 }
		mut digit2 := parity
		for digit2 < 10 {
			digits[left_index] = i64(digit2)
			result += count_reversible(remaining - 2, (carry_in + i64(digit1 + digit2)) / 10, mut digits, length)
			digit2 += 2
		}
	}
	return result
}

@[export: 'problem145']
pub fn problem145(max_power i64) i64 {
	if max_power > 9 { return -1 }
	if max_power <= 0 { return 0 }
	mut digits := [9]i64{}
	mut total := i64(0)
	for length in 1 .. int(max_power) + 1 {
		if (length - 1) % 4 != 0 { total += count_reversible(i64(length), 0, mut digits, i64(length)) }
	}
	return total
}
