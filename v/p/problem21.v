module problem21

fn proper_divisor_sum(value i64) i64 {
	if value <= 1 { return 0 }
	mut total := i64(1)
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 {
			partner := value / divisor
			total += divisor
			if partner != divisor { total += partner }
		}
		divisor++
	}
	return total
}

@[export: 'problem21']
pub fn problem21(limit i64) i64 {
	if limit < 1 || limit > 10000 { return -1 }
	mut total := i64(0)
	for value := i64(1); value < limit; value++ {
		partner := proper_divisor_sum(value)
		if partner != value && proper_divisor_sum(partner) == value { total += value }
	}
	return total
}
