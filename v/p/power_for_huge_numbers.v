module power_for_huge_numbers

const max_output_bytes = 513

@[export: 'power_for_huge_numbers']
pub fn power_for_huge_numbers(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length != 2 { return -1 }
	base := unsafe { input[0] }
	exponent := unsafe { input[1] }
	if base < 1 || base > 10000 || exponent < 0 || exponent > 128 { return -1 }
	mut digits := [max_output_bytes]u8{}
	digits[0] = 1
	mut digit_count := usize(1)
	for mut power := i64(0); power < exponent; power++ {
		mut carry := i64(0)
		for i in 0 .. digit_count {
			product := i64(digits[i]) * base + carry
			digits[i] = u8(product % 10)
			carry = product / 10
		}
		for carry != 0 {
			if digit_count == max_output_bytes { return -1 }
			digits[digit_count] = u8(carry % 10)
			digit_count++
			carry /= 10
		}
	}
	if output == nil || capacity < digit_count { return -2 }
	for i in 0 .. digit_count {
		unsafe { output[i] = u8(`0`) + digits[digit_count - 1 - i] }
	}
	return i64(digit_count)
}
