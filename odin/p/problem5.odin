package problem5

gcd :: proc(left, right: i64) -> i64 {
	a := left
	b := right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

@(export)
problem5 :: proc "c" (limit: i64) -> i64 {
	if limit < 1 || limit > 20 do return -1
	result := i64(1)
	for value := i64(2); value <= limit; value += 1 {
		result = (result / gcd(result, value)) * value
	}
	return result
}
