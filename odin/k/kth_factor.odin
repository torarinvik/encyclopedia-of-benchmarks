package kth_factor

@(export)
kth_factor :: proc "c" (n_value, k_value: i64) -> i64 {
	if n_value < 1 || n_value > 10000 || k_value < 1 || k_value > n_value do return -1
	n := i32(n_value)
	k := i32(k_value)
	factors_found := i32(0)
	i := i32(1)
	for i <= n {
		if n % i == 0 {
			factors_found += 1
			if factors_found == k do return i64(i)
		}
		i += 1
	}
	return -1
}
