module string_compression_ii

const max_n = 12
const max_input = 15
const width = max_n + 1
const cells = width * width
const infinity = i64(1000)

fn run_cost(kept int) i64 {
	if kept == 1 { return 1 }
	mut value := kept
	mut digits := 0
	for value > 0 { digits++; value /= 10 }
	return i64(1 + digits)
}

@[export: 'string_compression_ii']
pub fn string_compression_ii(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		raw_n := input[0]
		raw_k := input[1]
		if raw_n < 0 || raw_n > max_n || raw_k < 0 || raw_k > raw_n { return -1 }
		n := int(raw_n)
		budget := int(raw_k)
		if length != usize(n + 2) { return -1 }
		for i := 0; i < n; i++ { if input[i + 2] < 0 || input[i + 2] > 25 { return -1 } }

		mut dp := [cells]i64{init: infinity}
		dp[0] = 0
		for start := 0; start < n; start++ {
			for used := 0; used <= budget; used++ {
				prefix_cost := dp[start * width + used]
				if prefix_cost == infinity { continue }
				if used < budget {
					index := (start + 1) * width + used + 1
					if prefix_cost < dp[index] { dp[index] = prefix_cost }
				}
				mut same := 0
				for end := start; end < n; end++ {
					if input[end + 2] == input[start + 2] { same++ }
					span := end - start + 1
					for kept := 1; kept <= same; kept++ {
						deleted := used + span - kept
						if deleted > budget { continue }
						candidate := prefix_cost + run_cost(kept)
						index := (end + 1) * width + deleted
						if candidate < dp[index] { dp[index] = candidate }
					}
				}
			}
		}
		mut answer := infinity
		for deleted := 0; deleted <= budget; deleted++ {
			value := dp[n * width + deleted]
			if value < answer { answer = value }
		}
		return answer
	}
}
