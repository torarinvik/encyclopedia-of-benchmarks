module problem20

@[export: 'problem20']
pub fn problem20(n i64) i64 {
	if n < 0 || n > 100 { return -1 }
	mut digits := [200]i64{}
	digits[0] = 1
	mut length := 1
	mut factor := i64(2)
	for factor <= n {
		mut carry := i64(0)
		for index in 0 .. length {
			value := unsafe { digits[index] } * factor + carry
			digits[index] = value % 10
			carry = value / 10
		}
		for carry > 0 {
			digits[length] = carry % 10
			length++
			carry /= 10
		}
		factor++
	}
	mut sum := i64(0)
	for index in 0 .. length { sum += unsafe { digits[index] } }
	return sum
}
