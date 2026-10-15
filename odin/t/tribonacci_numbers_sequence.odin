package tribonacci_numbers_sequence

// Zero-based Tribonacci sequence with source seeds 1, 1, 1.
@(export)
tribonacci_numbers_sequence :: proc "c" (index: i64) -> i64 {
	if index < 0 || index > 60 do return -1
	if index < 3 do return 1

	first, second, third := i64(1), i64(1), i64(1)
	for i := i64(3); i <= index; i += 1 {
		next := first + second + third
		first = second
		second = third
		third = next
	}
	return third
}
