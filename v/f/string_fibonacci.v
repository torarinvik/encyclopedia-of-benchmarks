module string_fibonacci

const max_n = 256
const decimal_capacity = 80

fn add_decimal(left [decimal_capacity]u8, left_length int,
	right [decimal_capacity]u8, right_length int,
	mut result [decimal_capacity]u8) int {
	mut reversed := [decimal_capacity]u8{}
	mut left_remaining := left_length
	mut right_remaining := right_length
	mut length := 0
	mut carry := 0
	for left_remaining > 0 || right_remaining > 0 || carry != 0 {
		mut left_digit := 0
		mut right_digit := 0
		if left_remaining > 0 {
			left_remaining--
			left_digit = int(left[left_remaining] - 48)
		}
		if right_remaining > 0 {
			right_remaining--
			right_digit = int(right[right_remaining] - 48)
		}
		sum := left_digit + right_digit + carry
		reversed[length] = u8(48 + sum % 10)
		length++
		carry = sum / 10
	}
	for i in 0 .. length { result[i] = reversed[length - 1 - i] }
	result[length] = 0
	return length
}

@[export: 'string_fibonacci']
pub fn string_fibonacci(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	n := unsafe { input[0] }
	if n < 0 || n > max_n { return -1 }

	mut fib_minus_one := [decimal_capacity]u8{}
	mut fib_minus_two := [decimal_capacity]u8{}
	fib_minus_one[0] = 49
	fib_minus_two[0] = 48
	mut minus_one_length := 1
	mut minus_two_length := 1
	for _ in 0 .. int(n) {
		mut sum := [decimal_capacity]u8{}
		sum_length := add_decimal(fib_minus_one, minus_one_length,
			fib_minus_two, minus_two_length, mut sum)
		for i in 0 .. minus_one_length { fib_minus_two[i] = fib_minus_one[i] }
		minus_two_length = minus_one_length
		for i in 0 .. sum_length { fib_minus_one[i] = sum[i] }
		fib_minus_one[sum_length] = 0
		minus_one_length = sum_length
	}

	if unsafe { output == nil } || capacity < usize(minus_two_length) { return -2 }
	unsafe {
		for i in 0 .. minus_two_length { output[i] = fib_minus_two[i] }
	}
	return i64(minus_two_length)
}
