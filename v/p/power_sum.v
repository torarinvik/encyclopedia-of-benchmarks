module power_sum

fn power_sum_search(target i64, power i64, base i64, current_sum i64) i64 {
	mut term := i64(1)
	for _ in 0 .. power {
		term *= base
	}
	new_sum := current_sum + term
	if new_sum == target { return 1 }
	if new_sum > target { return 0 }
	return power_sum_search(target, power, base + 1, new_sum) + power_sum_search(target, power, base + 1, current_sum)
}

@[export: 'power_sum']
pub fn power_sum(packed &i64, length usize) i64 {
	if length != 2 { return -1 }
	target := unsafe { packed[0] }
	power := unsafe { packed[1] }
	if target < 1 || target > 1000 || power < 2 || power > 10 { return -1 }
	return power_sum_search(target, power, 1, 0)
}
