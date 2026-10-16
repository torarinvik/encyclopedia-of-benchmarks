module problem31_recursive

const max_target = 200
const coins = [8]i64{1, 2, 5, 10, 20, 50, 100, 200}

fn count_ways(target i64, coin_index int) i64 {
	if target < 0 { return 0 }
	if coin_index == 0 { return 1 }
	coin := coins[coin_index]
	return count_ways(target - coin, coin_index) + count_ways(target, coin_index - 1)
}

@[export: 'problem31_recursive']
pub fn problem31_recursive(target i64) i64 {
	if target < 0 || target > max_target { return -1 }
	return count_ways(target, 7)
}
