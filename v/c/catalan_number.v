module catalan_number

// Return the exact zero-based Catalan number through the signed 64-bit range.
@[export: 'catalan_number']
pub fn catalan_number(n i64) i64 {
	if n < 0 || n > 35 { return -1 }
	mut value := i64(1)
	mut index := i64(1)
	for index <= n {
		mut numerator := 4 * index - 2
		mut denominator := index + 1
		common := (if denominator % 3 == 0 { i64(3) } else { i64(1) }) * (if denominator % 2 == 0 { i64(2) } else { i64(1) })
		numerator /= common
		denominator /= common
		value = (value / denominator) * numerator
		index++
	}
	return value
}
