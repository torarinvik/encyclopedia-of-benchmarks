module problem63

@[export: 'problem63']
pub fn problem63(max_base i64, max_power i64) i64 {
	base_limit := if max_base > 10 { i64(10) } else { max_base }
	power_limit := if max_power > 22 { i64(22) } else { max_power }
	mut count := i64(0)
	mut base := i64(1)
	for base < base_limit {
		mut power := i64(1)
		for power < power_limit {
			mut digits := [32]int{}
			digits[0] = 1
			mut length := 1
			for _ in 0 .. int(power) {
				mut carry := 0
				for index in 0 .. length {
					value := digits[index] * int(base) + carry
					digits[index] = value % 10
					carry = value / 10
				}
				for carry > 0 {
					digits[length] = carry % 10
					length++
					carry /= 10
				}
			}
			if i64(length) == power { count++ }
			power++
		}
		base++
	}
	return count
}
