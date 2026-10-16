module problem87

const max_limit = 50_000_000
fn int_sqrt(value i64) i64 { mut root := i64(0); for (root + 1) * (root + 1) <= value { root++ }; return root }

@[export: 'problem87']
pub fn problem87(limit i64) i64 {
	if limit < 24 || limit > max_limit { return -1 }
	root_limit := int(max(int_sqrt(limit - 24), 2))
	mut prime := []bool{len: root_limit + 1, init: false}
	for p in 2 .. root_limit + 1 { prime[p] = true }
	for p in 2 .. int_sqrt(i64(root_limit)) + 1 {
		if prime[p] { mut multiple := p * p; for multiple <= root_limit { prime[multiple] = false; multiple += p } }
	}
	mut seen := []u8{len: int((limit + 7) / 8), init: 0}
	for p1 in 2 .. root_limit + 1 {
		if !prime[p1] { continue }
		square := i64(p1 * p1)
		for p2 in 2 .. root_limit + 1 {
			if !prime[p2] { continue }
			cube := i64(p2) * p2 * p2
			if square + cube >= limit - 16 { break }
			for p3 in 2 .. root_limit + 1 {
				if !prime[p3] { continue }
				total := square + cube + i64(p3) * p3 * p3 * p3
				if total >= limit { break }
				index := int(total)
				seen[index / 8] |= u8(1) << u8(index % 8)
			}
		}
	}
	mut count := i64(0)
	for bits0 in seen { mut bits := bits0; for bits != 0 { count++; bits &= bits - 1 } }
	return count
}
