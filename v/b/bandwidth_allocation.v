const max_users = 64

@[export: 'bandwidth_allocation']
pub fn bandwidth_allocation(input &i64, length usize) i64 {
	if isnil(input) || length < 2 { return -1 }
	bandwidth := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if bandwidth < 0 || bandwidth > 100_000 || count_value < 0 || count_value > max_users { return -1 }
	count := int(count_value)
	if length != usize(2 + 2 * count) { return -1 }
	for index in 0 .. count {
		demand := unsafe { input[2 + index] }
		value := unsafe { input[2 + count + index] }
		if demand < 1 || demand > 1_000 || value < 0 || value > 10_000 { return -1 }
	}

	mut ratios := [max_users]f64{}
	mut order := [max_users]int{}
	for index in 0 .. count {
		demand := unsafe { input[2 + index] }
		value := unsafe { input[2 + count + index] }
		ratios[index] = f64(value) / f64(demand)
		order[index] = index
	}
	for index in 1 .. count {
		key_ratio := ratios[index]
		key_index := order[index]
		mut position := index
		for position > 0 && ratios[position - 1] < key_ratio {
			ratios[position] = ratios[position - 1]
			order[position] = order[position - 1]
			position--
		}
		ratios[position] = key_ratio
		order[position] = key_index
	}

	mut remaining := bandwidth
	mut total := i64(0)
	for position in 0 .. count {
		index := order[position]
		demand := unsafe { input[2 + index] }
		value := unsafe { input[2 + count + index] }
		if remaining >= demand {
			total += value
			remaining -= demand
		} else {
			total += i64(ratios[position] * f64(remaining))
			break
		}
	}
	return total
}
