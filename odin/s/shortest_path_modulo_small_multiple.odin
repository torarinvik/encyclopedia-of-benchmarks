package shortest_path_modulo_small_multiple

import "core:c"

minimum_digit_sum :: proc(n: i64) -> i64 {
	distance: [16]i64
	deque: [512]int
	for i := 0; i < int(n); i += 1 { distance[i] = 1000 }
	head, tail, queued := 0, 0, 0
	start := int(1 % n)
	distance[start] = 1
	deque[tail] = start
	tail = (tail + 1) % 512
	queued += 1
	for queued > 0 {
		residue := deque[head]
		head = (head + 1) % 512
		queued -= 1
		zero_next := (i64(residue) * 10) % n
		if distance[int(zero_next)] > distance[residue] {
			distance[int(zero_next)] = distance[residue]
			head = (head + 511) % 512
			deque[head] = int(zero_next)
			queued += 1
		}
		one_next := (zero_next + 1) % n
		if distance[int(one_next)] > distance[residue] + 1 {
			distance[int(one_next)] = distance[residue] + 1
			deque[tail] = int(one_next)
			tail = (tail + 1) % 512
			queued += 1
		}
	}
	return distance[0]
}

@(export)
shortest_path_modulo_small_multiple :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n := input[0]
	if n < 1 || n > 16 do return -1
	return minimum_digit_sum(n)
}
