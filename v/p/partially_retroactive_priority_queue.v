module partially_retroactive_priority_queue

const max_n = 64
const max_q = 64
const max_input = usize(323)
const base = 128
const tree_size = 256

struct Segment {
	balance i64
	prefix_min i64
	suffix_max i64
	min_insert i64
	max_delete i64
}

struct RetroQueue {
	types [65]i64
	values [65]i64
	tree [tree_size]Segment
	live_count i64
	live_sum i64
}

fn pick_min_insert(q &RetroQueue, a i64, b i64) i64 {
	if a == 0 { return b }
	if b == 0 { return a }
	if q.values[int(a)] != q.values[int(b)] {
		return if q.values[int(a)] < q.values[int(b)] { a } else { b }
	}
	return if a > b { a } else { b }
}

fn pick_max_delete(q &RetroQueue, a i64, b i64) i64 {
	if a == -1 { return b }
	if b == -1 { return a }
	if a == 0 || b == 0 { return 0 }
	if q.values[int(a)] != q.values[int(b)] {
		return if q.values[int(a)] > q.values[int(b)] { a } else { b }
	}
	return if a < b { a } else { b }
}

fn pull(mut q RetroQueue, i int) {
	mut p := (base + i) / 2
	for p > 0 {
		left := q.tree[2 * p]
		right := q.tree[2 * p + 1]
		q.tree[p].balance = left.balance + right.balance
		through_min := left.balance + right.prefix_min
		q.tree[p].prefix_min = if left.prefix_min < through_min { left.prefix_min } else { through_min }
		through_max := left.suffix_max + right.balance
		q.tree[p].suffix_max = if through_max > right.suffix_max { through_max } else { right.suffix_max }
		q.tree[p].min_insert = pick_min_insert(&q, left.min_insert, right.min_insert)
		q.tree[p].max_delete = pick_max_delete(&q, left.max_delete, right.max_delete)
		p /= 2
	}
}

fn next_bridge(q &RetroQueue, i int) int {
	mut left := base
	mut right := base + i + 1
	mut acc := i64(0)
	for left < right {
		if (left & 1) == 1 { acc += q.tree[left].balance; left++ }
		if (right & 1) == 1 { right--; acc += q.tree[right].balance }
		left /= 2
		right /= 2
	}
	if acc == 0 { return i + 1 }
	mut node := base + i + 1
	for {
		for (node & 1) == 0 { node /= 2 }
		if acc + q.tree[node].prefix_min == 0 {
			for node < base {
				node *= 2
				if acc + q.tree[node].prefix_min > 0 { acc += q.tree[node].balance; node++ }
			}
			return node - base
		}
		acc += q.tree[node].balance
		node++
		if (node & -node) == node { return base }
	}
	return base
}

fn prev_bridge(q &RetroQueue, i int) int {
	mut left := base + i
	mut right := base * 2
	mut acc := i64(0)
	for left < right {
		if (left & 1) == 1 { acc += q.tree[left].balance; left++ }
		if (right & 1) == 1 { right--; acc += q.tree[right].balance }
		left /= 2
		right /= 2
	}
	if acc == 0 { return i }
	mut node := base + i
	for {
		node--
		for node > 1 && (node & 1) == 1 { node /= 2 }
		if q.tree[node].suffix_max + acc == 0 {
			for node < base {
				node = node * 2 + 1
				if q.tree[node].suffix_max + acc < 0 { acc += q.tree[node].balance; node-- }
			}
			return node - base
		}
		acc += q.tree[node].balance
		if (node & -node) == node { return 0 }
	}
	return 0
}

fn find_min_insert(q &RetroQueue, i int) i64 {
	mut left := base
	mut right := base + next_bridge(q, i)
	mut answer := i64(0)
	for left < right {
		if (left & 1) == 1 { answer = pick_min_insert(q, answer, q.tree[left].min_insert); left++ }
		if (right & 1) == 1 { right--; answer = pick_min_insert(q, answer, q.tree[right].min_insert) }
		left /= 2
		right /= 2
	}
	return answer
}

fn find_max_delete(q &RetroQueue, i int) i64 {
	mut left := base + prev_bridge(q, i)
	mut right := base * 2
	mut answer := i64(-1)
	for left < right {
		if (left & 1) == 1 { answer = pick_max_delete(q, answer, q.tree[left].max_delete); left++ }
		if (right & 1) == 1 { right--; answer = pick_max_delete(q, answer, q.tree[right].max_delete) }
		left /= 2
		right /= 2
	}
	return answer
}

fn add_operation(mut q RetroQueue, i int) {
	k := find_max_delete(&q, i)
	leaf := base + i
	if pick_max_delete(&q, i64(i), k) == i64(i) {
		q.live_sum += q.values[i]
		q.live_count++
		q.tree[leaf].min_insert = i64(i)
		pull(mut q, i)
		return
	}
	q.tree[leaf].max_delete = i64(i)
	q.tree[leaf].balance = 1
	q.tree[leaf].suffix_max = 1
	pull(mut q, i)
	mate := base + int(k)
	if k == 0 {
		q.tree[mate].balance--
		q.tree[mate].suffix_max--
		if q.tree[mate].balance == 0 { q.tree[mate].max_delete = -1 }
	} else {
		q.live_sum += q.values[int(k)]
		q.live_count++
		q.tree[mate].min_insert = k
		q.tree[mate].max_delete = -1
		q.tree[mate].balance = 0
		q.tree[mate].suffix_max = 0
	}
	pull(mut q, int(k))
}

fn remove_insert(mut q RetroQueue, i int) {
	leaf := base + i
	if q.tree[leaf].balance == 0 {
		q.live_sum -= q.values[i]
		q.live_count--
		q.tree[leaf].min_insert = 0
		pull(mut q, i)
		return
	}
	k := find_min_insert(&q, i)
	q.tree[leaf].max_delete = -1
	q.tree[leaf].balance = 0
	q.tree[leaf].suffix_max = 0
	pull(mut q, i)
	mate := base + int(k)
	if k > 0 { q.live_sum -= q.values[int(k)]; q.live_count-- }
	q.tree[mate].min_insert = 0
	q.tree[mate].max_delete = k
	q.tree[mate].balance++
	q.tree[mate].suffix_max++
	pull(mut q, int(k))
}

fn remove_minimum(mut q RetroQueue, i int) {
	k := find_min_insert(&q, i)
	leaf := base + i
	q.tree[leaf].balance = -1
	q.tree[leaf].prefix_min = -1
	pull(mut q, i)
	if k > 0 { q.live_sum -= q.values[int(k)]; q.live_count-- }
	mate := base + int(k)
	q.tree[mate].min_insert = 0
	q.tree[mate].max_delete = k
	q.tree[mate].balance++
	q.tree[mate].suffix_max++
	pull(mut q, int(k))
}

fn restore_minimum(mut q RetroQueue, i int) {
	k := find_max_delete(&q, i)
	leaf := base + i
	q.tree[leaf].balance = 0
	q.tree[leaf].prefix_min = 0
	pull(mut q, i)
	mate := base + int(k)
	if k == 0 {
		q.tree[mate].balance--
		q.tree[mate].suffix_max--
		if q.tree[mate].balance == 0 { q.tree[mate].max_delete = -1 }
	} else {
		q.live_sum += q.values[int(k)]
		q.live_count++
		q.tree[mate].min_insert = k
		q.tree[mate].max_delete = -1
		q.tree[mate].balance = 0
		q.tree[mate].suffix_max = 0
	}
	pull(mut q, int(k))
}

fn set_operation(mut q RetroQueue, index int, kind i64, value i64) {
	i := index + 1
	if q.types[i] == 0 { remove_insert(mut q, i) }
	else if q.types[i] == 1 { restore_minimum(mut q, i) }
	q.types[i] = kind
	q.values[i] = value
	if kind == 0 { add_operation(mut q, i) }
	else if kind == 1 { remove_minimum(mut q, i) }
}

fn store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'partially_retroactive_priority_queue']
pub fn partially_retroactive_priority_queue(input &i64, input_length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || input_length < 2 || input_length > max_input { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q { return -1 }
	n, qn := int(n_value), int(q_value)
	if input_length != usize(2 + 2*n + 3*qn) { return -1 }
	at := 2
	for _ in 0 .. n {
		kind := unsafe { input[at] }
		value := unsafe { input[at + 1] }
		at += 2
		if kind == 0 {
			if value < 0 || value > 1_000_000 { return -1 }
		} else if !((kind == 1 || kind == 2) && value == -1) { return -1 }
	}
	for _ in 0 .. qn {
		index := unsafe { input[at] }
		kind := unsafe { input[at + 1] }
		value := unsafe { input[at + 2] }
		at += 3
		if index < 0 || index >= n_value { return -1 }
		if kind == 0 {
			if value < 0 || value > 1_000_000 { return -1 }
		} else if !((kind == 1 || kind == 2) && value == -1) { return -1 }
	}
	output_size := 16 * qn
	if unsafe { output == nil } || capacity < usize(output_size) { return -2 }
	mut queue := RetroQueue{}
	for i in 0 .. max_n + 1 { queue.types[i] = 2; queue.values[i] = -1 }
	for i in 0 .. tree_size { queue.tree[i].max_delete = -1 }
	at = 2
	for i in 0 .. n {
		kind := unsafe { input[at] }
		value := unsafe { input[at + 1] }
		at += 2
		set_operation(mut queue, i, kind, value)
	}
	mut written := 0
	for _ in 0 .. qn {
		index := unsafe { input[at] }
		kind := unsafe { input[at + 1] }
		value := unsafe { input[at + 2] }
		at += 3
		set_operation(mut queue, int(index), kind, value)
		store_i64(mut output, written, queue.live_count)
		store_i64(mut output, written + 8, queue.live_sum)
		written += 16
	}
	return i64(written)
}
