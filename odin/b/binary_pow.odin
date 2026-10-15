package binary_pow

mul32 :: proc "contextless" (x, y: i64) -> i64 {
	x_low := x % 65_536
	x_high := x / 65_536
	y_low := y % 65_536
	y_high := y / 65_536
	cross := (x_low * y_high + x_high * y_low) % 65_536
	return (x_low * y_low + cross * 65_536) % 4_294_967_296
}

@(export)
binary_pow :: proc "contextless" (first, second: i64) -> i64 {
	if first < -2_147_483_648 || first > 2_147_483_647 || second < -2_147_483_648 || second > 2_147_483_647 do return -2_147_483_649
	if second <= 0 do return 1
	base := first
	if base < 0 do base += 4_294_967_296
	exponent := second
	result := i64(1)
	for exponent > 0 {
		if exponent % 2 == 1 do result = mul32(result, base)
		base = mul32(base, base)
		exponent /= 2
	}
	if result >= 2_147_483_648 do return result - 4_294_967_296
	return result
}
