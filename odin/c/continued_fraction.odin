package continued_fraction

import "core:c"

gcd_positive :: proc "contextless" (left_value, right_value: i64) -> i64 {
	left, right := left_value, right_value
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

@(export)
continued_fraction :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	numerator, denominator := input[0], input[1]
	if numerator < -1000000 || numerator > 1000000 || denominator < -1000000 ||
		denominator > 1000000 || denominator == 0 do return -1
	divisor := gcd_positive(abs(numerator), abs(denominator))
	numerator /= divisor
	denominator /= divisor
	if denominator < 0 { numerator = -numerator; denominator = -denominator }
	coefficients: [32]i64
	count := 0
	for {
		quotient := numerator / denominator
		remainder := numerator % denominator
		if remainder < 0 { quotient -= 1; remainder += denominator }
		if count == len(coefficients) do return -1
		coefficients[count] = quotient
		count += 1
		if remainder == 0 do break
		numerator, denominator = denominator, remainder
	}
	bytes := count * 8
	if c.size_t(bytes) > capacity || output == nil do return -2
	for index := 0; index < count; index += 1 {
		bits := transmute(u64)coefficients[index]
		for byte: int = 0; byte < 8; byte += 1 { output[index * 8 + byte] = u8(bits >> u64(byte * 8)) }
	}
	return i64(bytes)
}
