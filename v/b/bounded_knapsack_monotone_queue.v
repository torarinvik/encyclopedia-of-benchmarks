module bounded_knapsack_monotone_queue

// Bounded knapsack by residue-class sliding maxima.
@[export: 'bounded_knapsack_monotone_queue']
pub fn bounded_knapsack_monotone_queue(packed &i64, length usize) i64 {
	if unsafe { packed == nil } { return -1 }
	if length < 2 || length > 51 { return -1 }
	if unsafe { packed[0] } < 0 || unsafe { packed[0] } > 64 || unsafe { packed[1] } < 0 || unsafe { packed[1] } > 16 { return -1 }
	capacity := int(unsafe { packed[0] })
	types := int(unsafe { packed[1] })
	if length != usize(2 + 3 * types) { return -1 }
	for item in 0 .. types {
		weight := unsafe { packed[2 + 3 * item] }
		value := unsafe { packed[3 + 3 * item] }
		count := unsafe { packed[4 + 3 * item] }
		if weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16 { return -1 }
	}

	mut dp := [65]i64{}
	mut next := [65]i64{}
	mut queue_score := [65]i64{}
	mut queue_index := [65]int{}
	for item in 0 .. types {
		weight := int(unsafe { packed[2 + 3 * item] })
		value := unsafe { packed[3 + 3 * item] }
		count := int(unsafe { packed[4 + 3 * item] })
		for residue := 0; residue < weight && residue <= capacity; residue++ {
			mut head := 0
			mut tail := 0
			max_t := (capacity - residue) / weight
			for t := 0; t <= max_t; t++ {
				current := residue + t * weight
				score := dp[current] - i64(t) * value
				for tail > head && queue_score[tail - 1] <= score { tail-- }
				queue_index[tail] = t
				queue_score[tail] = score
				tail++
				first_allowed := if t > count { t - count } else { 0 }
				for head < tail && queue_index[head] < first_allowed { head++ }
				next[current] = i64(t) * value + queue_score[head]
			}
		}
		for c := 0; c <= capacity; c++ { dp[c] = next[c] }
	}
	return dp[capacity]
}
