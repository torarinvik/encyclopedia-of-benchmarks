module coin_change

// Return the minimum number of unlimited coins needed to reach an amount.
@[export: 'coin_change']
pub fn coin_change(packed &i64, length usize) i64 {
	if length < 2 || length > 130 { return -1 }
	amount := unsafe { packed[0] }
	coin_count := unsafe { packed[1] }
	if amount < 0 || amount > 512 || coin_count < 0 || coin_count > 128 { return -1 }
	if length != usize(2 + coin_count) { return -1 }
	for coin_index in 0 .. usize(coin_count) {
		denomination := unsafe { packed[2 + coin_index] }
		if denomination < 1 || denomination > 4096 { return -1 }
	}

	mut minimum := [513]i64{init: 0}
	mut current := i64(1)
	for current <= amount {
		mut best := i64(513)
		for coin_index in 0 .. usize(coin_count) {
			coin := unsafe { packed[2 + coin_index] }
			if coin <= current && minimum[int(current - coin)] < 513 {
				candidate := minimum[int(current - coin)] + 1
				if candidate < best { best = candidate }
			}
		}
		minimum[int(current)] = best
		current++
	}
	if minimum[int(amount)] < 513 { return minimum[int(amount)] }
	return -1
}
