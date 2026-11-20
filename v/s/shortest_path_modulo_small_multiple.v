module shortest_path_modulo_small_multiple

fn minimum_digit_sum(n i64) i64 {
	mut distance := [16]i64{init: 1000}
	mut deque := [512]int{}
	mut head := 0
	mut tail := 0
	mut queued := 0
	start := int(1 % n)
	distance[start] = 1
	deque[tail] = start
	tail = (tail + 1) % 512
	queued++
	for queued > 0 {
		residue := deque[head]
		head = (head + 1) % 512
		queued--
		zero_next := int((i64(residue) * 10) % n)
		if distance[zero_next] > distance[residue] {
			distance[zero_next] = distance[residue]
			head = (head + 511) % 512
			deque[head] = zero_next
			queued++
		}
		one_next := int((i64(zero_next) + 1) % n)
		if distance[one_next] > distance[residue] + 1 {
			distance[one_next] = distance[residue] + 1
			deque[tail] = one_next
			tail = (tail + 1) % 512
			queued++
		}
	}
	return distance[0]
}

@[export: 'shortest_path_modulo_small_multiple']
pub fn shortest_path_modulo_small_multiple(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		n := input[0]
		if n < 1 || n > 16 { return -1 }
		return minimum_digit_sum(n)
	}
}
