module finding_number_of_digits_in_a_number

@[export: 'finding_number_of_digits_in_a_number']
pub fn finding_number_of_digits_in_a_number(value i64) i64 {
	if value < 0 { return -1 }
	mut remaining := u64(value)
	mut count := i64(0)
	for remaining != 0 {
		remaining /= 10
		count++
	}
	return count
}
