package stable_matching

import "core:c"

MAX_N :: 8
MAX_INPUT_LENGTH :: 129

@(export, link_name="stable_matching")
stable_matching :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_arg := input[0]
	if n_arg < 0 || n_arg > MAX_N do return -1
	n := int(n_arg)
	side_size := n * n
	if length != c.size_t(1 + 2 * side_size) do return -1

	men_preferences: [64]i64
	women_rank: [64]i64
	for row := 0; row < 2 * n; row += 1 {
		seen: [MAX_N]bool
		for id := 0; id < MAX_N; id += 1 { seen[id] = false }
		row_start := 1 + row * n
		if row >= n { row_start = 1 + side_size + (row - n) * n }
		for rank := 0; rank < n; rank += 1 {
			participant := input[row_start + rank]
			if participant < 0 || participant >= n_arg || seen[int(participant)] do return -1
			seen[int(participant)] = true
			if row < n { men_preferences[row * n + rank] = participant }
			else { women_rank[(row - n) * n + int(participant)] = i64(rank) }
		}
	}

	output_bytes := c.size_t(16 * n)
	if output == nil || capacity < output_bytes do return -2

	woman_partner: [MAX_N]i64
	man_partner: [MAX_N]i64
	next_proposal: [MAX_N]int
	free_queue: [MAX_N]int
	for index := 0; index < n; index += 1 {
		woman_partner[index] = -1
		man_partner[index] = -1
		next_proposal[index] = 0
		free_queue[index] = index
	}
	head, tail, queue_count := 0, 0, n
	for queue_count > 0 {
		man := free_queue[head]
		head = (head + 1) % n
		queue_count -= 1
		rank := next_proposal[man]
		next_proposal[man] += 1
		woman := int(men_preferences[man * n + rank])
		incumbent := woman_partner[woman]
		if incumbent < 0 {
			woman_partner[woman] = i64(man)
			man_partner[man] = i64(woman)
		} else if women_rank[woman * n + man] < women_rank[woman * n + int(incumbent)] {
			woman_partner[woman] = i64(man)
			man_partner[man] = i64(woman)
			man_partner[int(incumbent)] = -1
			free_queue[tail] = int(incumbent)
			tail = (tail + 1) % n
			queue_count += 1
		} else {
			free_queue[tail] = man
			tail = (tail + 1) % n
			queue_count += 1
		}
	}

	for man := 0; man < n; man += 1 {
		pair := [2]i64{i64(man), man_partner[man]}
		for item := 0; item < 2; item += 1 {
			bits := transmute(u64)(pair[item])
			for byte := 0; byte < 8; byte += 1 {
				output[(man * 2 + item) * 8 + byte] = u8(bits & 255)
				bits >>= 8
			}
		}
	}
	return i64(output_bytes)
}
