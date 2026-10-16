package problem55

const MAX_LIMIT :: 10_000
const MAX_DIGITS :: 64

reverse_add :: proc "contextless" (digits: [^]u8, length: int) -> int {
	reverse_length := length
	for reverse_length > 0 && digits[length-reverse_length] == 0 do reverse_length -= 1
	combined_length := max(length, reverse_length)
	next: [MAX_DIGITS]u8 = {}
	carry := 0
	for position := 0; position < combined_length; position += 1 {
		left := if position < length then int(digits[position]) else 0
		right := if position < reverse_length then int(digits[length-1-position]) else 0
		sum := left + right + carry
		next[position] = u8(sum % 10)
		carry = sum / 10
	}
	next_length := combined_length
	if carry > 0 {
		next[next_length] = u8(carry)
		next_length += 1
	}
	for index := 0; index < next_length; index += 1 do digits[index] = next[index]
	return next_length
}

is_palindrome :: proc "contextless" (digits: [^]u8, length: int) -> bool {
	for left := 0; left < length / 2; left += 1 {
		if digits[left] != digits[length-1-left] do return false
	}
	return true
}

@(export)
problem55 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > MAX_LIMIT do return -1
	count := i64(0)
	for start := i64(1); start < limit; start += 1 {
		digits: [MAX_DIGITS]u8 = {}
		length := 0
		value := start
		for value > 0 {
			digits[length] = u8(value % 10)
			length += 1
			value /= 10
		}
		became_palindrome := false
		for iteration := 0; iteration < 50; iteration += 1 {
			length = reverse_add(&digits[0], length)
			if is_palindrome(&digits[0], length) {
				became_palindrome = true
				break
			}
		}
		if !became_palindrome do count += 1
	}
	return count
}
