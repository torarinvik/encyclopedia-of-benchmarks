module dynamic_coin_change_solver

@[export: 'dynamic_coin_change_solver']
pub fn dynamic_coin_change_solver(input &i64, length usize) i64 {
	unsafe {
		if length < 3 || length > 11 { return -1 }
		amount := input[0]; count := input[1]
		if amount < 1 || amount > 18 || count < 1 || count > 9 || length != usize(count + 2) { return -1 }
		mut coins := [9]int{}
		mut has_one := false
		for i in 0 .. int(count) {
			if input[i + 2] < 1 || input[i + 2] > 9 { return -1 }
			coins[i] = int(input[i + 2])
			if coins[i] == 1 { has_one = true }
			for j in 0 .. i { if coins[i] == coins[j] { return -1 } }
		}
		if !has_one { return -1 }
		for i in 0 .. int(count) { for j in i + 1 .. int(count) { if coins[i] < coins[j] { coins[i], coins[j] = coins[j], coins[i] } } }
		mut changes := [19][9]int{}
		mut sizes := [19]int{}
		for value in 1 .. int(amount) + 1 {
			for i in 0 .. int(count) { if coins[i] <= value { changes[value][sizes[value]] = value - coins[i]; sizes[value]++ } }
		}
		mut current := int(amount)
		mut code := i64(0)
		for _ in 0 .. 18 {
			mut next := 2147483647
			mut min_change := 2147483647
			for i in 0 .. sizes[current] {
				change := changes[current][i]
				if change == 0 { next = 0; break }
				mut minimum := 2147483647
				for j in 0 .. sizes[change] { if changes[change][j] < minimum { minimum = changes[change][j] } }
				if minimum < min_change { min_change = minimum; next = change }
			}
			if next == 2147483647 { return -1 }
			code = code * 10 + i64(current - next)
			if next == 0 { return code }
			current = next
		}
		return -1
	}
}
