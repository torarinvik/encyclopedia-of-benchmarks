module parity

@[export: 'parity']
pub fn parity(number i64) i64 {
	if number < 0 { return -1 }
	mut current := number
	mut result := i64(0)
	for current != 0 {
		result ^= 1
		current &= current - 1
	}
	return result
}
