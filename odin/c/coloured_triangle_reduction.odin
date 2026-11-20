package coloured_triangle_reduction

import "core:c"

triangle_binomial_mod_three :: proc(n, k: i64) -> i64 {
	coefficient := i64(1)
	remaining_n := n
	remaining_k := k
	for remaining_n > 0 || remaining_k > 0 {
		n_digit := remaining_n % 3
		k_digit := remaining_k % 3
		if k_digit > n_digit do return 0
		if n_digit == 2 && k_digit == 1 do coefficient = (2 * coefficient) % 3
		remaining_n /= 3
		remaining_k /= 3
	}
	return coefficient
}

@(export)
coloured_triangle_reduction :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 258 do return -1
	n := input[0]
	if n < 1 || n > 256 || length != c.size_t(n + 1) do return -1
	for index := 0; index < int(n); index += 1 {
		color := input[index + 1]
		if color < 0 || color > 2 do return -1
	}

	rounds := n - 1
	total := i64(0)
	for index := 0; index < int(n); index += 1 {
		total = (total + triangle_binomial_mod_three(rounds, i64(index)) * input[index + 1]) % 3
	}
	return if rounds % 2 == 0 then total else (3 - total) % 3
}
