module optimal_stable_marriage

const (
	max_n = 8
	max_input_length = 129
)

@[export: 'optimal_stable_marriage']
pub fn optimal_stable_marriage(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_input_length { return -1 }
	n_arg := unsafe { input[0] }
	if n_arg < 0 || n_arg > i64(max_n) { return -1 }
	n := int(n_arg)
	side_size := n * n
	if length != 1 + 2 * side_size { return -1 }

	mut men_preferences := [64]int{}
	mut women_rank := [64]int{}
	for row in 0 .. 2 * n {
		mut seen := [8]bool{}
		start := if row < n { 1 + row * n } else { 1 + side_size + (row - n) * n }
		for rank in 0 .. n {
			value := unsafe { input[start + rank] }
			if value < 0 || value >= n_arg || seen[int(value)] { return -1 }
			participant := int(value)
			seen[participant] = true
			if row < n { men_preferences[row * n + rank] = participant }
			else { women_rank[(row - n) * n + participant] = rank }
		}
	}
	output_bytes := 16 * n
	if output == nil || capacity < usize(output_bytes) { return -2 }

	mut final_partner := [8]i64{}
	for man in 0 .. n { final_partner[man] = -1 }
	for threshold in 0 .. n {
		mut woman_partner := [8]i64{}
		mut man_partner := [8]i64{}
		mut next_rank := [8]int{}
		mut queue := [8]int{}
		for i in 0 .. n {
			woman_partner[i] = -1
			man_partner[i] = -1
			queue[i] = i
		}
		mut head := 0
		mut tail := 0
		mut queued := n
		for queued > 0 {
			man := queue[head]
			head = (head + 1) % n
			queued--
			for next_rank[man] < n {
				rank := next_rank[man]
				next_rank[man]++
				woman := men_preferences[man * n + rank]
				if rank > threshold || women_rank[woman * n + man] > threshold { continue }
				incumbent := woman_partner[woman]
				if incumbent < 0 || women_rank[woman * n + man] < women_rank[woman * n + int(incumbent)] {
					woman_partner[woman] = i64(man)
					man_partner[man] = i64(woman)
					if incumbent >= 0 {
						man_partner[int(incumbent)] = -1
						queue[tail] = int(incumbent)
						tail = (tail + 1) % n
						queued++
					}
					break
				}
				queue[tail] = man
				tail = (tail + 1) % n
				queued++
				break
			}
		}
		mut matched := 0
		for man in 0 .. n { if man_partner[man] >= 0 { matched++ } }
		if matched == n {
			for man in 0 .. n { final_partner[man] = man_partner[man] }
			break
		}
	}
	for man in 0 .. n {
		values := [2]i64{i64(man), final_partner[man]}
		for item in 0 .. 2 {
			mut bits := u64(values[item])
			for byte in 0 .. 8 {
				unsafe { output[(man * 2 + item) * 8 + byte] = u8(bits & 255) }
				bits >>= 8
			}
		}
	}
	return i64(output_bytes)
}
