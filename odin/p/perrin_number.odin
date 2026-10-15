package perrin_number

@(export)
perrin_number :: proc "c" (index: i64) -> i64 {
	if index < 0 || index > 155 do return -1
	if index == 0 do return 3
	if index == 1 do return 0
	if index == 2 do return 2
	a, b, c := i64(3), i64(0), i64(2)
	result := i64(0)
	for i := i64(3); i <= index; i += 1 {
		result = a + b
		a = b
		b = c
		c = result
	}
	return result
}
