module kth_factor

@[export: 'kth_factor']
pub fn kth_factor(n_value i64, k_value i64) i64 {
	if n_value < 1 || n_value > 10000 || k_value < 1 || k_value > n_value { return -1 }
	n := i32(n_value)
	k := i32(k_value)
	mut factors_found := i32(0)
	mut i := i32(1)
	for i <= n {
		if n % i == 0 {
			factors_found += 1
			if factors_found == k { return i64(i) }
		}
		i++
	}
	return -1
}
