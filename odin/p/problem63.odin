package problem63

@(export)
problem63 :: proc "c" (max_base, max_power: i64) -> i64 {
	base_limit := max_base
	if base_limit > 10 do base_limit = 10
	power_limit := max_power
	if power_limit > 22 do power_limit = 22
	count := i64(0)
	for base := i64(1); base < base_limit; base += 1 {
		for power := i64(1); power < power_limit; power += 1 {
			digits: [32]int
			digits[0] = 1
			length := 1
			for exponent := i64(0); exponent < power; exponent += 1 {
				carry := 0
				for index := 0; index < length; index += 1 {
					value := digits[index] * int(base) + carry
					digits[index] = value % 10
					carry = value / 10
				}
				for carry > 0 {
					digits[length] = carry % 10
					length += 1
					carry /= 10
				}
			}
			if i64(length) == power { count += 1 }
		}
	}
	return count
}
