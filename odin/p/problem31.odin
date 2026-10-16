package problem31

const MAX_TARGET :: 500

@(export)
problem31 :: proc "c" (target: i64) -> i64 {
	if target < 0 || target > MAX_TARGET do return -1
	coins: [8]i64 = {1, 2, 5, 10, 20, 50, 100, 200}
	ways: [MAX_TARGET + 1]i64 = {}
	ways[0] = 1
	for coin_index := 0; coin_index < 8; coin_index += 1 {
		coin := coins[coin_index]
		for amount := coin; amount <= target; amount += 1 {
			ways[amount] += ways[amount - coin]
		}
	}
	return ways[target]
}
