module uniform_numbers

// Count positive repdigits up to the input using the pinned prefix formula.
@[export: 'uniform_numbers']
pub fn uniform_numbers(value i64) i64 {
	if value < 0 || value > 999999999 { return -1 }
	mut remaining := value
	mut first_digit := i64(0)
	mut digits := i64(0)
	for {
		first_digit = remaining % 10
		remaining /= 10
		digits++
		if remaining == 0 { break }
	}
	mut repeated := i64(0)
	for _ in 0 .. int(digits) { repeated = repeated * 10 + first_digit }
	count := (digits - 1) * 9
	if repeated <= value { return count + first_digit }
	return count + first_digit - 1
}
