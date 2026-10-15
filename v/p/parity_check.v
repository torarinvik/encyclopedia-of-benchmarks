@[export: 'parity_check']
pub fn parity_check(value i64) i64 {
	if value < -2147483648 || value > 2147483647 { return -1 }
	mut number := i32(value)
	mut parity := 0
	for number > 0 {
		parity ^= number & 1
		number >>= 1
	}
	return if parity == 0 { 1 } else { 0 }
}
