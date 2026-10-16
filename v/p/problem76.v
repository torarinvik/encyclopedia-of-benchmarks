module problem76

const max_total = 200
const max_parts = 200
const memo_size = (max_total + 1) * max_parts

@[export: 'problem76']
pub fn problem76(total i64) i64 {
	if total < 1 || total > max_total { return -1 }
	bound := int(total)
	mut memo := [memo_size]i64{}
	for n in 0 .. bound + 1 { memo[n * max_parts] = 1 }
	for n in 0 .. bound + 1 {
		for k in 1 .. bound {
			index := n * max_parts + k
			memo[index] += memo[index - 1]
			if n > k { memo[index] += memo[(n - k - 1) * max_parts + k] }
		}
	}
	return memo[bound * max_parts + bound - 1] - 1
}
