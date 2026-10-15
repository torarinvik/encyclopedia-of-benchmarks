module check_factorial

@[export: 'check_factorial']
pub fn check_factorial(n i64) i64 {
	if n <= 0 {
		return 0
	}
	mut value := n
	mut divisor := i64(2)
	for value % divisor == 0 {
		value /= divisor
		divisor++
	}
	return if value == 1 { 1 } else { 0 }
}
