module keith_number_checker

// Preserve the digit-window recurrence used by the pinned C# checker.
@[export: 'keith_number_checker']
pub fn keith_number_checker(number i64) i64 {
	if number < 2 || number > 1000 { return -1 }
	original := number
	mut temp := number
	mut digits := i64(0)
	for temp != 0 {
		digits++
		temp /= 10
	}

	mut terms := []i64{len: int(number), init: 0}
	temp = number
	mut i := digits
	for i > 0 {
		i--
		terms[int(i)] = temp % 10
		temp /= 10
	}
	mut sum := i64(0)
	mut k := digits
	for sum < original {
		sum = 0
		for j := i64(1); j <= digits; j++ { sum += terms[int(k - j)] }
		terms[int(k)] = sum
		k++
	}
	return if sum == original { i64(1) } else { i64(0) }
}
