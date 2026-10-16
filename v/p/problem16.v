module problem16

@[export: 'problem16']
pub fn problem16(exponent i64) i64 {
	if exponent < 0 || exponent > 1000 { return -1 }
	mut digits := [400]int{}
	digits[0] = 1
	mut length := 1
	for _ in 0 .. int(exponent) {
		mut carry := 0
		for index in 0 .. length {
			value := digits[index] * 2 + carry
			digits[index] = value % 10
			carry = value / 10
		}
		for carry > 0 {
			digits[length] = carry % 10
			length++
			carry /= 10
		}
	}
	mut total := i64(0)
	for index in 0 .. length { total += i64(digits[index]) }
	return total
}
