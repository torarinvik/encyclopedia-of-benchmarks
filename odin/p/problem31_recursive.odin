package problem31_recursive

const MAX_TARGET :: 200

coin_value :: proc "contextless" (coin_index: int) -> i64 {
	switch coin_index {
	case 1: return 2
	case 2: return 5
	case 3: return 10
	case 4: return 20
	case 5: return 50
	case 6: return 100
	case: return 200
	}
}

count_ways :: proc "contextless" (target: i64, coin_index: int) -> i64 {
	if target < 0 do return 0
	if coin_index == 0 do return 1
	coin := coin_value(coin_index)
	return count_ways(target - coin, coin_index) + count_ways(target, coin_index - 1)
}

@(export)
problem31_recursive :: proc "c" (target: i64) -> i64 {
	if target < 0 || target > MAX_TARGET do return -1
	return count_ways(target, 7)
}
