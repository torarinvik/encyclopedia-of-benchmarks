package problem16

@(export)
problem16 :: proc "c" (exponent: i64) -> i64 {
	if exponent < 0 || exponent > 1000 do return -1
	digits: [400]i64 = {}
	digits[0] = 1
	length := 1
	for power := i64(0); power < exponent; power += 1 {
		carry := i64(0)
		for index := 0; index < length; index += 1 {
			value := digits[index] * 2 + carry
			digits[index] = value % 10
			carry = value / 10
		}
		for carry > 0 {
			digits[length] = carry % 10
			length += 1
			carry /= 10
		}
	}
	total := i64(0)
	for index := 0; index < length; index += 1 {
		total += digits[index]
	}
	return total
}
