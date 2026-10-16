package problem122

solve :: proc(chain: []i64, length: int, goal: i64, depth: int) -> bool {
	last := chain[length - 1]
	for index := 0; index < length; index += 1 {
		next := chain[index] + last
		if next == goal do return true
		if next > goal do break
		if length < depth { chain[length] = next; if solve(chain, length + 1, goal, depth) do return true }
	}
	return false
}

@(export)
problem122 :: proc "c" (maximum: i64) -> i64 {
	if maximum < 0 || maximum > 200 do return -1
	total := i64(0)
	for goal := i64(2); goal <= maximum; goal += 1 {
		chain: [32]i64 = {}
		chain[0] = 1
		depth := 0
		for {
			depth += 1
			chain[0] = 1
			if solve(chain[:], 1, goal, depth) do break
		}
		total += i64(depth)
	}
	return total
}
