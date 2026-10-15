package padovan_sequence

@(export)
padovan_sequence :: proc "c" (index: i64) -> i64 {
	if index < 0 || index > 156 do return -1
	if index <= 2 do return 1
	a, b, c := i64(1), i64(1), i64(1)
	result := i64(0)
	for i := i64(3); i <= index; i += 1 {
		result = a + b
		a = b
		b = c
		c = result
	}
	return result
}
