package mccat_qbsort
import "core:c"

bubble :: proc(a: ^[32]i32, n: int) {
	if n < 2 do return
	for end := n; end > 1; end -= 1 {
		for i := 0; i + 1 < end; i += 1 { if a[i + 1] < a[i] { t := a[i]; a[i] = a[i + 1]; a[i + 1] = t } }
	}
}
Pool :: struct { values: [560]i32, links: [560]int, used: int }
quick :: proc(pool: ^Pool, head: int) -> int {
	if head < 0 do return -1
	pivot := pool.values[head]
	lower, upper := -1, -1
	current := pool.links[head]
	for current >= 0 {
		value := pool.values[current]
		following := pool.links[current]
		created := pool.used
		pool.used += 1
		pool.values[created] = value
		if value < pivot { pool.links[created] = lower; lower = created } else { pool.links[created] = upper; upper = created }
		current = following
	}
	sorted_upper := quick(pool, upper)
	sorted_lower := quick(pool, lower)
	pivot_node := pool.used
	pool.used += 1
	pool.values[pivot_node] = pivot
	pool.links[pivot_node] = sorted_upper
	if sorted_lower < 0 do return pivot_node
	tail := sorted_lower
	for pool.links[tail] >= 0 { tail = pool.links[tail] }
	pool.links[tail] = pivot_node
	return sorted_lower
}
@(export)
mccat_qbsort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 34 do return -1
	mode, cv := input[0], input[1]
	if (mode != 0 && mode != 1) || cv < 1 || cv > 32 do return -1
	n := int(cv); if length != c.size_t(n + 2) do return -1
	values: [32]i32 = {}
	for i := 0; i < n; i += 1 { v := input[i + 2]; if v < -2147483648 || v > 2147483647 do return -1; values[i] = i32(v) }
	for pass := 0; pass < 1000; pass += 1 {
		for i := 0; i < n; i += 1 { values[i] = i32(input[i + 2]) }
		if mode == 0 { bubble(&values, n) } else {
			pool: Pool
			pool.used = n
			for i := 0; i < n; i += 1 {
				pool.values[i] = values[i]
				pool.links[i] = -1
				if i + 1 < n { pool.links[i] = i + 1 }
			}
			current := quick(&pool, 0)
			i := 0
			for current >= 0 {
				values[i] = pool.values[current]
				current = pool.links[current]
				i += 1
			}
		}
	}
	need := 4 * n; if output == nil || capacity < c.size_t(need) do return -2
	for i := 0; i < n; i += 1 { bits := u32(values[i]); for b := 0; b < 4; b += 1 { output[i * 4 + b] = u8((bits >> (8 * b)) & 255) } }
	return i64(need)
}
