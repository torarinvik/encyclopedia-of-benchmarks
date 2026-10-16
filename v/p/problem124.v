module problem124

@[export: 'problem124']
pub fn problem124(n_max i64, k i64) i64 {
	if n_max < 1 || n_max > 100000 || k < 1 || k > n_max { return -1 }
	n := int(n_max)
	mut radicals := [100001]i64{}
	mut counts := [100001]i64{}
	for i in 1 .. (n + 1) { radicals[i] = 1 }
	for p in 2 .. (n + 1) {
		if radicals[p] == 1 {
			for multiple := p; multiple <= n; multiple += p { radicals[multiple] *= i64(p) }
		}
	}
	for i in 1 .. (n + 1) { counts[int(radicals[i])]++ }
	mut remaining := k
	for rad in 1 .. (n + 1) {
		if remaining > counts[rad] { remaining -= counts[rad]; continue }
		for value in 1 .. (n + 1) {
			if radicals[value] == i64(rad) {
				remaining--
				if remaining == 0 { return i64(value) }
			}
		}
	}
	return -1
}
