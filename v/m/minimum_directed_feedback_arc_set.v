module minimum_directed_feedback_arc_set

const max_n = 8
const max_m = 56
const max_length = 114
const max_states = 256
const inf = i64(2305843009213693951)

@[export: 'minimum_directed_feedback_arc_set']
pub fn minimum_directed_feedback_arc_set(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length + 1 { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_m { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + 2*m) { return -1 }

		mut outgoing := [max_n]int{}
		for edge in 0 .. m {
			tail_value := input[2 + 2*edge]
			head_value := input[3 + 2*edge]
			if tail_value < 0 || head_value < 0 || tail_value >= i64(n) || head_value >= i64(n) || tail_value == head_value { return -1 }
			tail := int(tail_value)
			head := int(head_value)
			bit := 1 << head
			if (outgoing[tail] & bit) != 0 { return -1 }
			outgoing[tail] |= bit
		}

		full := (1 << n)-1
		mut dp := [max_states]i64{}
		for mask in 0 .. max_states { dp[mask] = inf }
		dp[0] = 0
		for prefix in 0 .. full+1 {
			if dp[prefix] == inf { continue }
			for vertex in 0 .. n {
				bit := 1 << vertex
				if (prefix & bit) != 0 { continue }
				mut backward := i64(0)
				for prior in 0 .. n {
					if (prefix & (1 << prior)) != 0 && (outgoing[vertex] & (1 << prior)) != 0 {
						backward += 1
					}
				}
				target := prefix | bit
				candidate := dp[prefix] + backward
				if candidate < dp[target] { dp[target] = candidate }
			}
		}
		return dp[full]
	}
}
