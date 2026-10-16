package largest_of_very_large_numbers

MAX_VALUE :: i64(1000000000000)

decimal_exponent :: proc "contextless" (base: i64) -> i64 {
	if base < 1 do return -1
	exponent := i64(0)
	for base > 1 && base % 10 == 0 {
		base /= 10
		exponent += 1
	}
	if base == 1 do return exponent
	return -1
}

valid_base :: proc "contextless" (base: i64) -> bool {
	return base == 0 || decimal_exponent(base) >= 0
}

source_score :: proc "contextless" (base, exponent: i64) -> i64 {
	if base == 0 do return 0
	if exponent == 0 do return 1
	return decimal_exponent(base) * exponent
}

@(export)
largest_of_very_large_numbers :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 4 do return -2
	for i := 0; i < 4; i += 1 { if values[i] < 0 || values[i] > MAX_VALUE do return -2 }
	if !valid_base(values[0]) || !valid_base(values[2]) do return -2
	a := source_score(values[0], values[1])
	b := source_score(values[2], values[3])
	if a > b do return 1
	if a < b do return -1
	return 0
}
