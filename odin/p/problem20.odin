package problem20

@(export)
problem20 :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 100 do return -1
	digits: [200]i64 = {}
	digits[0] = 1
	length := 1
	factor := i64(2)
	for factor <= n {
		carry := i64(0)
		for index := 0; index < length; index += 1 {
			value := digits[index] * factor + carry
			digits[index] = value % 10
			carry = value / 10
		}
		for carry > 0 {
			digits[length] = carry % 10
			length += 1
			carry /= 10
		}
		factor += 1
	}
	sum := i64(0)
	for index := 0; index < length; index += 1 { sum += digits[index] }
	return sum
}
