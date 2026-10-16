module problem122

fn solve(mut chain []i64, length int, goal i64, depth int) bool {
	last := chain[length - 1]
	for index in 0 .. length {
		next := chain[index] + last
		if next == goal { return true }
		if next > goal { break }
		if length < depth { chain[length] = next; if solve(mut chain, length + 1, goal, depth) { return true } }
	}
	return false
}

@[export: 'problem122']
pub fn problem122(maximum i64) i64 {
	if maximum < 0 || maximum > 200 { return -1 }
	mut total := i64(0)
	for goal in 2 .. int(maximum) + 1 {
		mut chain := []i64{len: 32}
		chain[0] = 1
		mut depth := 0
		for {
			depth++
			chain[0] = 1
			if solve(mut chain, 1, i64(goal), depth) { break }
		}
		total += i64(depth)
	}
	return total
}
