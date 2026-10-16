package dynamic_coin_change_solver

@(export, link_name="dynamic_coin_change_solver")
dynamic_coin_change_solver :: proc "c" (input: [^]i64, length: uint) -> i64 {
	if input == nil || length < 3 || length > 11 do return -1
	amount, count := input[0], input[1]
	if amount < 1 || amount > 18 || count < 1 || count > 9 || length != uint(count + 2) do return -1
	coins: [9]int
	has_one := false
	for i := 0; i < int(count); i += 1 {
		if input[i + 2] < 1 || input[i + 2] > 9 do return -1
		coins[i] = int(input[i + 2])
		if coins[i] == 1 do has_one = true
		for j := 0; j < i; j += 1 { if coins[i] == coins[j] do return -1 }
	}
	if !has_one do return -1
	for i := 0; i < int(count); i += 1 { for j := i + 1; j < int(count); j += 1 { if coins[i] < coins[j] do coins[i], coins[j] = coins[j], coins[i] } }
	changes: [19][9]int
	sizes: [19]int
	for value := 1; value <= int(amount); value += 1 {
		for i := 0; i < int(count); i += 1 { if coins[i] <= value { changes[value][sizes[value]] = value - coins[i]; sizes[value] += 1 } }
	}
	current := int(amount)
	code: i64 = 0
	for step := 0; step < 18; step += 1 {
		next, min_change := int(2147483647), int(2147483647)
		for i := 0; i < sizes[current]; i += 1 {
			change := changes[current][i]
			if change == 0 { next = 0; break }
			minimum := int(2147483647)
			for j := 0; j < sizes[change]; j += 1 { if changes[change][j] < minimum do minimum = changes[change][j] }
			if minimum < min_change { min_change = minimum; next = change }
		}
		if next == 2147483647 do return -1
		code = code * 10 + i64(current - next)
		if next == 0 do return code
		current = next
	}
	return -1
}

main :: proc() {}
