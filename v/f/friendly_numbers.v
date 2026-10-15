module friendly_numbers

// Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior.
fn abundancy_index(number u64) f64 {
	mut sum := number
	mut divisor := u64(1)
	for divisor * 2 < number {
		if number % divisor == 0 { sum += divisor }
		divisor++
	}
	return f64(sum) / f64(number)
}

@[export: 'friendly_numbers']
pub fn friendly_numbers(first u64, second u64) i64 {
	if first == 0 || second == 0 || first == second || first > 1000 || second > 1000 { return -1 }
	if abundancy_index(first) == abundancy_index(second) { return 1 }
	return 0
}
