package vampire_number

decimal_length :: proc "contextless" (value_input: u64) -> u32 {
	value := value_input
	length: u32 = 0
	for {
		length += 1
		value /= 10
		if value == 0 do break
	}
	return length
}

@(export)
vampire_number :: proc "c" (left_input, right_input: u64) -> i64 {
	if left_input < 1 || left_input > 9999 || right_input < 1 || right_input > 9999 do return -1
	if decimal_length(left_input) != decimal_length(right_input) do return 0
	counts: [10]i64
	left, right := left_input, right_input
	product := left * right
	for product != 0 {
		counts[int(product % 10)] += 1
		product /= 10
	}
	for left != 0 {
		counts[int(left % 10)] -= 1
		left /= 10
	}
	for right != 0 {
		counts[int(right % 10)] -= 1
		right /= 10
	}
	for count in counts {
		if count != 0 do return 0
	}
	return 1
}
