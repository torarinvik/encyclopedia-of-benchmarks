package minimum_coin_change_combinations

import "core:c"

MAX_INPUT :: 34

@(export)
minimum_coin_change_combinations :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	target, count_value := input[0], input[1]
	if target < -64 || target > 64 || count_value < 0 || count_value > 32 do return -1
	count := int(count_value)
	if int(length) != count + 2 do return -1

	previous: i64 = 0
	for index := 0; index < count; index += 1 {
		coin := input[2 + index]
		if coin < 1 || coin > 64 || coin <= previous do return -1
		previous = coin
	}
	if target < 0 do return 0

	ways: [65]i64 = {}
	ways[0] = 1
	target_int := int(target)
	for coin_index := 0; coin_index < count; coin_index += 1 {
		coin := int(input[2 + coin_index])
		for amount := coin; amount <= target_int; amount += 1 {
			ways[amount] += ways[amount - coin]
		}
	}
	return ways[target_int]
}
