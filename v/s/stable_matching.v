module stable_matching

const (
	max_n = 8
	max_input_length = 129
)

@[export: 'stable_matching']
pub fn stable_matching(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_input_length {
		return -1
	}
	n_arg := unsafe { input[0] }
	if n_arg < 0 || n_arg > i64(max_n) {
		return -1
	}
	n := int(n_arg)
	side_size := n * n
	if length != 1 + 2 * side_size {
		return -1
	}

	mut men_preferences := [64]i64{}
	mut women_rank := [64]i64{}
	for row in 0 .. 2 * n {
		mut seen := [8]bool{}
		row_start := if row < n { 1 + row * n } else { 1 + side_size + (row - n) * n }
		for rank in 0 .. n {
			participant := unsafe { input[row_start + rank] }
			if participant < 0 || participant >= n_arg || seen[int(participant)] {
				return -1
			}
			seen[int(participant)] = true
			if row < n {
				men_preferences[row * n + rank] = participant
			} else {
				women_rank[(row - n) * n + int(participant)] = i64(rank)
			}
		}
	}

	output_bytes := 16 * n
	if output == nil || capacity < usize(output_bytes) {
		return -2
	}

	mut woman_partner := [8]i64{}
	mut man_partner := [8]i64{}
	mut next_proposal := [8]int{}
	mut free_queue := [8]int{}
	for index in 0 .. n {
		woman_partner[index] = -1
		man_partner[index] = -1
		free_queue[index] = index
	}
	mut head := 0
	mut tail := 0
	mut queue_count := n
	for queue_count > 0 {
		man := free_queue[head]
		head = (head + 1) % n
		queue_count--
		rank := next_proposal[man]
		next_proposal[man]++
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
			queue_count++
		} else {
			free_queue[tail] = man
			tail = (tail + 1) % n
			queue_count++
		}
	}

	for man in 0 .. n {
		pair := [2]i64{i64(man), man_partner[man]}
		for item in 0 .. 2 {
			mut bits := u64(pair[item])
			for byte in 0 .. 8 {
				unsafe { output[(man * 2 + item) * 8 + byte] = u8(bits & 255) }
				bits >>= 8
			}
		}
	}
	return i64(output_bytes)
}
