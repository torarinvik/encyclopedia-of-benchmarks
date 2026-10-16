module problem136

@[export: 'problem136']
pub fn problem136(n_limit i64) i64 {
	if n_limit > 100000 { return -1 }
	if n_limit <= 0 { return 0 }
	mut solutions := [100000]u8{}
	max_delta := (n_limit + 1) / 4
	for delta := i64(1); delta <= max_delta; delta++ {
		mut y := 4 * delta - 1
		for y > delta {
			n := y * (4 * delta - y)
			if n >= n_limit { break }
			if solutions[int(n)] < 2 { solutions[int(n)]++ }
			y--
		}
	}
	mut answer := i64(0)
	for n in 0 .. int(n_limit) { if solutions[n] == 1 { answer++ } }
	return answer
}
