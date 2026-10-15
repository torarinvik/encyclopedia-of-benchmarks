module vampire_number

fn decimal_length(value_input u64) int {
	mut value := value_input
	mut length := 0
	for {
		length++
		value /= 10
		if value == 0 { break }
	}
	return length
}

// Match the product's decimal digits against the combined factor digits.
@[export: 'vampire_number']
pub fn vampire_number(left_input u64, right_input u64) i64 {
	if left_input < 1 || left_input > 9999 || right_input < 1 || right_input > 9999 { return -1 }
	if decimal_length(left_input) != decimal_length(right_input) { return 0 }
	mut counts := [10]int{}
	mut product := left_input * right_input
	mut left := left_input
	mut right := right_input
	for product != 0 {
		counts[int(product % 10)]++
		product /= 10
	}
	for left != 0 {
		counts[int(left % 10)]--
		left /= 10
	}
	for right != 0 {
		counts[int(right % 10)]--
		right /= 10
	}
	for count in counts {
		if count != 0 { return 0 }
	}
	return 1
}
