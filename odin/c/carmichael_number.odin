package carmichael_number

is_composite :: proc(n: i64) -> bool {
	if n < 4 do return false
	for divisor := i64(2); divisor <= n / divisor; divisor += 1 {
		if n % divisor == 0 do return true
	}
	return false
}

modular_power :: proc(base, exponent, modulus: i64) -> i64 {
	if exponent == 0 do return 1
	half := modular_power(base, exponent / 2, modulus) % modulus
	result := (half * half) % modulus
	if exponent % 2 != 0 do result = (result * base) % modulus
	return result
}

gcd :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@(export)
carmichael_number :: proc "c" (value: i64) -> i64 {
	if value < 1 || value > 10000 do return -1
	if value < 3 || !is_composite(value) do return 0
	for base := i64(2); base < value; base += 1 {
		if gcd(base, value) == 1 && modular_power(base, value - 1, value) != 1 do return 0
	}
	return 1
}
