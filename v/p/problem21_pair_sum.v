module problem21_pair_sum

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

@[export: 'problem21_pair_sum']
pub fn problem21_pair_sum(limit i64) i64 {
	if limit < 2 || limit > 10000 { return -1 }
	mut total := i64(0)
	mut smaller := i64(2)
	for smaller < limit {
		larger := proper_divisor_sum(smaller)
		if larger > smaller && proper_divisor_sum(larger) == smaller {
			total += smaller + larger
		}
		smaller++
	}
	return total
}
