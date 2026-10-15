package finding_number_of_digits_in_a_number

@(export)
finding_number_of_digits_in_a_number :: proc "c" (value: i64) -> i64 {
	if value < 0 do return -1
	remaining := u64(value)
	count := i64(0)
	for remaining != 0 {
		remaining /= 10
		count += 1
	}
	return count
}
