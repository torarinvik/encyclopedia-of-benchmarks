package min_of_mod_of_linear

import "core:c"

floor_sum :: proc(n_input, m_input, a_input, b_input: i64) -> i64 {
	n, m, a, b := n_input, m_input, a_input, b_input
	answer: i64 = 0
	for {
		if a >= m {
			quotient := a / m
			left, right := n, n-1
			if left % 2 == 0 do left /= 2 else right /= 2
			answer += left * right * quotient
			a %= m
		}
		if b >= m {
			answer += n * (b / m)
			b %= m
		}
		numerator := a * n + b
		height := numerator / m
		if height == 0 do return answer
		b = numerator % m
		n = height
		previous_m := m
		m = a
		a = previous_m
	}
}

@(export)
min_of_mod_of_linear :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	MAX_PARAMETER :: i64(1_000_000_000)
	if input == nil || length != 4 do return -1
	n, m, a, b := input[0], input[1], input[2], input[3]
	if n < 1 || n > MAX_PARAMETER || m < 1 || m > MAX_PARAMETER do return -1
	if a < 0 || a >= m || b < 0 || b >= m do return -1
	target := floor_sum(n, m, a, b) + n
	low := i64(-1)
	high := m - 1
	for high-low > 1 {
		candidate := low + (high-low)/2
		shift := m - 1 - candidate
		if floor_sum(n, m, a, b+shift) < target do high = candidate else low = candidate
	}
	return high
}
