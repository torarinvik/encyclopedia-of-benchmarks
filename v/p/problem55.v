module problem55

const max_limit = i64(10_000)
const max_digits = 64

fn reverse_add(mut digits &u8, length int) int {
	mut reverse_length := length
	for reverse_length > 0 && unsafe { digits[length - reverse_length] == 0 } {
		reverse_length--
	}
	combined_length := if length > reverse_length { length } else { reverse_length }
	mut next := [max_digits]u8{}
	mut carry := 0
	for position in 0 .. combined_length {
		left := if position < length { int(unsafe { digits[position] }) } else { 0 }
		right := if position < reverse_length { int(unsafe { digits[length - 1 - position] }) } else { 0 }
		sum := left + right + carry
		next[position] = u8(sum % 10)
		carry = sum / 10
	}
	mut next_length := combined_length
	if carry > 0 {
		next[next_length] = u8(carry)
		next_length++
	}
	for index in 0 .. next_length {
		unsafe { digits[index] = next[index] }
	}
	return next_length
}

fn is_palindrome(digits &u8, length int) bool {
	for left in 0 .. length / 2 {
		if unsafe { digits[left] != digits[length - 1 - left] } { return false }
	}
	return true
}

@[export: 'problem55']
pub fn problem55(limit i64) i64 {
	if limit < 0 || limit > max_limit { return -1 }
	mut count := i64(0)
	for start := i64(1); start < limit; start++ {
		mut digits := [max_digits]u8{}
		mut length := 0
		mut value := start
		for value > 0 {
			digits[length] = u8(value % 10)
			length++
			value /= 10
		}
		mut became_palindrome := false
		for _ in 0 .. 50 {
			length = reverse_add(mut digits, length)
			if is_palindrome(digits, length) {
				became_palindrome = true
				break
			}
		}
		if !became_palindrome { count++ }
	}
	return count
}
