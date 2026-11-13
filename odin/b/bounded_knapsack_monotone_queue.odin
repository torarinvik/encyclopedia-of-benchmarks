package bounded_knapsack_monotone_queue

import "core:c"

// Bounded knapsack by residue-class sliding maxima.
@(export)
bounded_knapsack_monotone_queue :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 51 do return -1
	if packed[0] < 0 || packed[0] > 64 || packed[1] < 0 || packed[1] > 16 do return -1
	capacity := int(packed[0])
	types := int(packed[1])
	if length != c.size_t(2 + 3 * types) do return -1
	for item := 0; item < types; item += 1 {
		weight := packed[2 + 3 * item]
		value := packed[3 + 3 * item]
		count := packed[4 + 3 * item]
		if weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16 do return -1
	}

	dp: [65]i64 = {}
	next: [65]i64 = {}
	queue_score: [65]i64 = {}
	queue_index: [65]int = {}
	for item := 0; item < types; item += 1 {
		weight := int(packed[2 + 3 * item])
		value := packed[3 + 3 * item]
		count := int(packed[4 + 3 * item])
		for residue := 0; residue < weight && residue <= capacity; residue += 1 {
			head, tail := 0, 0
			max_t := (capacity - residue) / weight
			for t := 0; t <= max_t; t += 1 {
				current := residue + t * weight
				score := dp[current] - i64(t) * value
				for tail > head && queue_score[tail - 1] <= score { tail -= 1 }
				queue_index[tail] = t
				queue_score[tail] = score
				tail += 1
				first_allowed := 0
				if t > count { first_allowed = t - count }
				for head < tail && queue_index[head] < first_allowed { head += 1 }
				next[current] = i64(t) * value + queue_score[head]
			}
		}
		for c := 0; c <= capacity; c += 1 { dp[c] = next[c] }
	}
	return dp[capacity]
}
