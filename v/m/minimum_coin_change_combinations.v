module minimum_coin_change_combinations

const max_input = 34

@[export: 'minimum_coin_change_combinations']
pub fn minimum_coin_change_combinations(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	unsafe {
		target, count_value := input[0], input[1]
		if target < -64 || target > 64 || count_value < 0 || count_value > 32 { return -1 }
		count := int(count_value)
		if length != usize(count + 2) { return -1 }

		mut previous := i64(0)
		for index in 0 .. count {
			coin := input[2 + index]
			if coin < 1 || coin > 64 || coin <= previous { return -1 }
			previous = coin
		}
		if target < 0 { return 0 }

		mut ways := [65]i64{}
		ways[0] = 1
		for coin_index in 0 .. count {
			coin := int(input[2 + coin_index])
			for amount := coin; amount <= int(target); amount++ {
				ways[amount] += ways[amount - coin]
			}
		}
		return ways[int(target)]
	}
}
