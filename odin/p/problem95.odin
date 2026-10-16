package problem95

MAX_LIMIT :: 1_000_000
MARK :: u32(0x80000000)
MASK :: u32(0x7fffffff)

@(export)
problem95 :: proc "c" (limit: i64) -> i64 {
	if limit < 1 || limit > MAX_LIMIT do return -1
	n := int(limit)
	sums := make([]u32, n + 1)
	defer delete(sums)
	for divisor := 1; divisor <= n / 2; divisor += 1 {
		for multiple := 2 * divisor; multiple <= n; multiple += divisor { sums[multiple] += u32(divisor) }
	}
	best_length := 0
	answer := i64(0)
	for start := 2; start <= n; start += 1 {
		current := sums[start]
		length := 1
		sums[start] |= MARK
		for current > 1 && current <= u32(n) && (sums[current] & MARK) == 0 {
			sums[current] |= MARK
			current = sums[current] & MASK
			length += 1
		}
		if current == u32(start) && length > best_length { best_length = length; answer = i64(start) }
		current = u32(start)
		for step := 0; step < length; step += 1 { next := sums[current] & MASK; sums[current] = next; current = next }
	}
	return answer
}
