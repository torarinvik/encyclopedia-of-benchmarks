module problem3

@[export: 'problem3']
pub fn problem3(number i64) i64 {
	if number < 2 || number > 600_851_475_143 { return -1 }
	mut remaining := number
	mut largest := i64(1)
	mut factor := i64(2)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			largest = factor
			remaining /= factor
		} else {
			factor++
		}
	}
	if remaining > 1 { return remaining }
	return largest
}
