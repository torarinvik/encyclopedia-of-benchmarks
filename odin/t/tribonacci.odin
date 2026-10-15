package tribonacci

// Portable zero-based Tribonacci recurrence for the shared i64 contract.
@(export)
tribonacci :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 73 do return -1
	if n == 0 do return 0
	if n <= 2 do return 1
	previous_three, previous_two, previous_one: i64 = 0, 1, 1
	for index: i64 = 3; index <= n; index += 1 {
		next := previous_three + previous_two + previous_one
		previous_three = previous_two
		previous_two = previous_one
		previous_one = next
	}
	return previous_one
}
