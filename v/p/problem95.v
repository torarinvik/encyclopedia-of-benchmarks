module problem95

const max_limit = 1_000_000
const mark = u32(0x80000000)
const value_mask = u32(0x7fffffff)

@[export: 'problem95']
pub fn problem95(limit i64) i64 {
	if limit < 1 || limit > max_limit { return -1 }
	n := int(limit)
	mut sums := []u32{len: n + 1, init: 0}
	for divisor in 1 .. n / 2 + 1 {
		mut multiple := 2 * divisor
		for multiple <= n { sums[multiple] += u32(divisor); multiple += divisor }
	}
	mut best_length := 0
	mut answer := i64(0)
	for start in 2 .. n + 1 {
		mut current := sums[start]
		mut length := 1
		sums[start] |= mark
		for current > 1 && current <= u32(n) && (sums[int(current)] & mark) == 0 {
			sums[int(current)] |= mark
			current = sums[int(current)] & value_mask
			length++
		}
		if current == u32(start) && length > best_length { best_length = length; answer = i64(start) }
		current = u32(start)
		for _ in 0 .. length { next := sums[int(current)] & value_mask; sums[int(current)] = next; current = next }
	}
	return answer
}
