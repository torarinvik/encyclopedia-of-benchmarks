package coin_change

import "core:c"

// Return the minimum number of unlimited coins needed to reach an amount.
@(export)
coin_change :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 130 do return -1
	amount := packed[0]
	coin_count := packed[1]
	if amount < 0 || amount > 512 || coin_count < 0 || coin_count > 128 do return -1
	if length != c.size_t(2 + coin_count) do return -1
	for coin_index := c.size_t(0); coin_index < c.size_t(coin_count); coin_index += 1 {
		if packed[2 + coin_index] < 1 || packed[2 + coin_index] > 4096 do return -1
	}

	minimum: [513]i64
	for current := 1; current <= int(amount); current += 1 {
		best := i64(513)
		for coin_index := c.size_t(0); coin_index < c.size_t(coin_count); coin_index += 1 {
			coin := int(packed[2 + coin_index])
			if coin <= current && minimum[current - coin] < 513 {
				candidate := minimum[current - coin] + 1
				if candidate < best do best = candidate
			}
		}
		minimum[current] = best
	}
	if minimum[int(amount)] < 513 do return minimum[int(amount)]
	return -1
}
