module minimum_cost_to_merge_stones

const max_n = 30
const max_k = 30
const max_input_length = 33
const dp_cells = max_n * max_n * (max_k + 1)
const infinity = i64(1152921504606846976)

fn dp_index(left int, right int, piles int) int {
	return (left * max_n + right) * (max_k + 1) + piles
}

@[export: 'minimum_cost_to_merge_stones']
pub fn minimum_cost_to_merge_stones(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 2 || input[1] > max_k { return -1 }
		n := int(input[0])
		merge_count := int(input[1])
		if length != usize(n + 2) { return -1 }

		mut prefix := [max_n + 1]i64{}
		for i in 0 .. n {
			stone := input[i + 2]
			if stone < 1 || stone > 100 { return -1 }
			prefix[i + 1] = prefix[i] + stone
		}
		if (n - 1) % (merge_count - 1) != 0 { return -1 }

		mut dp := [dp_cells]i64{}
		for i in 0 .. dp_cells { dp[i] = infinity }
		for i in 0 .. n { dp[dp_index(i, i, 1)] = 0 }
		for interval_length in 2 .. n + 1 {
			for left in 0 .. n - interval_length + 1 {
				right := left + interval_length - 1
				maximum_piles := if merge_count < interval_length { merge_count } else { interval_length }
				for piles in 2 .. maximum_piles + 1 {
					mut best := infinity
					for cut in left .. right {
						first := dp[dp_index(left, cut, 1)]
						rest := dp[dp_index(cut + 1, right, piles - 1)]
						if first < infinity && rest < infinity && first + rest < best { best = first + rest }
					}
					dp[dp_index(left, right, piles)] = best
				}
				if interval_length >= merge_count {
					to_k := dp[dp_index(left, right, merge_count)]
					if to_k < infinity { dp[dp_index(left, right, 1)] = to_k + prefix[right + 1] - prefix[left] }
				}
			}
		}
		answer := dp[dp_index(0, n - 1, 1)]
		if answer >= infinity { return -1 }
		return answer
	}
}
