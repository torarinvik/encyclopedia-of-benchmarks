module mccat_qbsort

fn bubble(mut a []i32) {
	if a.len < 2 { return }
	for end := a.len; end > 1; end-- {
		for i := 0; i + 1 < end; i++ { if a[i + 1] < a[i] { t := a[i]; a[i] = a[i + 1]; a[i + 1] = t } }
	}
}
struct Pool {
mut:
	nodes []i32
	links []int
	used int
}

fn quick(mut pool Pool, head int) int {
	if head < 0 { return -1 }
	pivot := pool.nodes[head]
	mut lower := -1
	mut upper := -1
	mut current := pool.links[head]
	for current >= 0 {
		value := pool.nodes[current]
		following := pool.links[current]
		created := pool.used
		pool.used++
		pool.nodes[created] = value
		if value < pivot { pool.links[created] = lower; lower = created } else { pool.links[created] = upper; upper = created }
		current = following
	}
	sorted_upper := quick(mut pool, upper)
	sorted_lower := quick(mut pool, lower)
	pivot_node := pool.used
	pool.used++
	pool.nodes[pivot_node] = pivot
	pool.links[pivot_node] = sorted_upper
	if sorted_lower < 0 { return pivot_node }
	mut tail := sorted_lower
	for pool.links[tail] >= 0 { tail = pool.links[tail] }
	pool.links[tail] = pivot_node
	return sorted_lower
}

@[export: 'mccat_qbsort']
pub fn mccat_qbsort(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 3 || length > 34 { return -1 }
	mode := unsafe { input[0] }; count_value := unsafe { input[1] }
	if (mode != 0 && mode != 1) || count_value < 1 || count_value > 32 { return -1 }
	n := int(count_value)
	if length != usize(n + 2) { return -1 }
	mut values := []i32{len: n, init: 0}
	for i in 0 .. n {
		value := unsafe { input[i + 2] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[i] = i32(value)
	}
	for _ in 0 .. 1000 {
		for i in 0 .. n { values[i] = i32(unsafe { input[i + 2] }) }
		if mode == 0 { bubble(mut values) } else {
			mut pool := Pool{nodes: []i32{len: 560}, links: []int{len: 560}, used: n}
			for i in 0 .. n {
				pool.nodes[i] = values[i]
				pool.links[i] = if i + 1 < n { i + 1 } else { -1 }
			}
			mut current := quick(mut pool, 0)
			mut i := 0
			for current >= 0 {
				values[i] = pool.nodes[current]
				current = pool.links[current]
				i++
			}
		}
	}
	need := n * 4
	if output == nil || output_capacity < usize(need) { return -2 }
	for i in 0 .. n {
		bits := u32(values[i])
		for b in 0 .. 4 { unsafe { output[i * 4 + b] = u8((bits >> (8 * b)) & 255) } }
	}
	return i64(need)
}
