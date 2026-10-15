@[export: 'amicable_number']
fn amicable_number(left u64, right u64) i64 {
	if left < 1 || left > 1_000_000_000 || right < 1 || right > 1_000_000_000 { return -1 }
	if left == right { return 0 }
	mut sum_left := u64(1)
	mut divisor := u64(2)
	for divisor <= left / divisor {
		if left % divisor == 0 {
			sum_left += divisor
			partner := left / divisor
			if partner != divisor { sum_left += partner }
		}
		divisor++
	}
	mut sum_right := u64(1)
	divisor = 2
	for divisor <= right / divisor {
		if right % divisor == 0 {
			sum_right += divisor
			partner := right / divisor
			if partner != divisor { sum_right += partner }
		}
		divisor++
	}
	return i64(sum_left == right && sum_right == left)
}
