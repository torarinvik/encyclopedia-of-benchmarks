package problem87

MAX_LIMIT :: 50_000_000

@(export)
problem87 :: proc "c" (limit: i64) -> i64 {
	if limit < 24 || limit > MAX_LIMIT do return -1
	root_limit := i64(0)
	for (root_limit + 1) * (root_limit + 1) <= limit - 24 { root_limit += 1 }
	if root_limit < 2 do root_limit = 2
	prime: [7072]bool = {}
	for p := i64(2); p <= root_limit; p += 1 { prime[p] = true }
	for p := i64(2); p * p <= root_limit; p += 1 {
		if prime[p] { for multiple := p * p; multiple <= root_limit; multiple += p { prime[multiple] = false } }
	}
	bytes := int((limit + 7) / 8)
	seen := make([]u8, bytes)
	defer delete(seen)
	for p1 := i64(2); p1 <= root_limit; p1 += 1 {
		if !prime[p1] do continue
		square := p1 * p1
		for p2 := i64(2); p2 <= root_limit; p2 += 1 {
			if !prime[p2] do continue
			cube := p2 * p2 * p2
			if square + cube >= limit - 16 do break
			for p3 := i64(2); p3 <= root_limit; p3 += 1 {
				if !prime[p3] do continue
				total := square + cube + p3 * p3 * p3 * p3
				if total >= limit do break
				index := int(total)
				seen[index / 8] |= u8(1) << u8(index % 8)
			}
		}
	}
	count := i64(0)
	for bits0 in seen {
		bits := bits0
		for bits != 0 { count += 1; bits &= bits - 1 }
	}
	return count
}
