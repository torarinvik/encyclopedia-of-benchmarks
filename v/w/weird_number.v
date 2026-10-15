module weird_number

// Return whether a value is abundant and not semiperfect.
@[export: 'weird_number']
pub fn weird_number(value i64) i64 {
	if value < 0 || value > 512 { return -1 }
	if value == 0 { return 0 }
	mut reachable := [513]bool{}
	reachable[0] = true
	mut divisor_sum := i64(0)
	for mut divisor := i64(1); divisor <= value / 2; divisor++ {
		if value % divisor != 0 { continue }
		divisor_sum += divisor
		mut total := value
		for total >= divisor {
			if reachable[int(total - divisor)] { reachable[int(total)] = true }
			total--
		}
	}
	return if divisor_sum > value && !reachable[int(value)] { 1 } else { 0 }
}
