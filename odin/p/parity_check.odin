package parity_check

@(export)
parity_check :: proc "c" (value: i64) -> i64 {
	if value < -2147483648 || value > 2147483647 do return -1
	number := i32(value)
	parity: i32 = 0
	for number > 0 {
		parity ^= number & 1
		number >>= 1
	}
	if parity == 0 do return 1
	return 0
}
