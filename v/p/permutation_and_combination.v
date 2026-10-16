@[export: 'permutation_and_combination']
pub fn permutation_and_combination(v &i64, n usize) i64 {
	unsafe {
		if v == nil || n != 3 { return -1 }
		op, a, r := v[0], v[1], v[2]
		if op < 0 || op > 2 || a < 0 || a > 18 { return -1 }
		if op != 0 && (r < 0 || r > a) { return -1 }
		mut result := i64(1)
		if op == 0 { for i := i64(2); i <= a; i++ { result *= i } }
		else if op == 1 { for i := a - r + 1; i <= a; i++ { result *= i } }
		else {
			mut k := r; if k > a - k { k = a - k }
			for i := i64(1); i <= k; i++ { result = result * (a - k + i) / i }
		}
		return result
	}
}
