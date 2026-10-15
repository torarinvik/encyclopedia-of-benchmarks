module max_69_number

@[export: 'max_69_number']
pub fn max_69_number(value i64) i64 {
	if value < 1 || value > 999999999999999999 { return -1 }
	mut place := i64(1)
	for place <= value / 10 { place *= 10 }
	for place > 0 {
		digit := (value / place) % 10
		if digit == 6 { return value + 3 * place }
		if digit != 9 { return -1 }
		place /= 10
	}
	return -1
}
