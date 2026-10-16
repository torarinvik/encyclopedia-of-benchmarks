module problem72

@[export: 'problem72']
pub fn problem72(limit i64) i64 {
	if limit < 0 || limit > 1_000_000 { return -1 }
	if limit < 2 { return 0 }
	n := int(limit)
	mut phi := []u32{len: n + 1}
	if n >= 1 { phi[1] = 1 }
	for value in 2 .. n + 1 { phi[value] = u32(value) }
	for prime in 2 .. n + 1 {
		if phi[prime] == u32(prime) {
			mut multiple := prime
			for multiple <= n {
				phi[multiple] -= phi[multiple] / u32(prime)
				multiple += prime
			}
		}
	}
	mut total := i64(0)
	for denominator in 2 .. n + 1 { total += i64(phi[denominator]) }
	return total
}
