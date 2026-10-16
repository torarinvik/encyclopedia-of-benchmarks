package problem7

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	for factor := i64(2); factor <= value / factor; factor += 1 {
		if value % factor == 0 do return false
	}
	return true
}

@(export)
problem7 :: proc "c" (index: i64) -> i64 {
	if index < 1 || index > 10_001 do return -1
	count := i64(0)
	candidate := i64(1)
	for count < index {
		candidate += 1
		if is_prime(candidate) do count += 1
	}
	return candidate
}
