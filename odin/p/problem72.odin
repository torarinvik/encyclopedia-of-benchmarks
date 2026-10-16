package problem72

@(export)
problem72 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 1_000_000 do return -1
	if limit < 2 do return 0
	phi: [1_000_001]u32 = {}
	if limit >= 1 do phi[1] = 1
	for value := i64(2); value <= limit; value += 1 { phi[value] = u32(value) }
	for prime := i64(2); prime <= limit; prime += 1 {
		if phi[prime] == u32(prime) {
			for multiple := prime; multiple <= limit; multiple += prime {
				phi[multiple] -= phi[multiple] / u32(prime)
			}
		}
	}
	total := i64(0)
	for denominator := i64(2); denominator <= limit; denominator += 1 { total += i64(phi[denominator]) }
	return total
}
