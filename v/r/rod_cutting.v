module rod_cutting

@[export: 'rod_cutting']
pub fn rod_cutting(values &i64, length usize) i64 {
	if length < 2 { return -1 }
	n_value := unsafe { values[0] }
	if n_value < 1 || n_value > 30 { return -1 }
	n := usize(n_value)
	if length != n + 1 { return -1 }
	for i in 0 .. n {
		price := unsafe { values[i + 1] }
		if price < 1 || price > 1000 { return -1 }
	}
	mut profit := [31]i64{}
	for rod := 1; rod <= n; rod++ {
		mut best := i64(0)
		for cut := 1; cut <= rod; cut++ {
			candidate := unsafe { values[cut] } + profit[rod - cut]
			if candidate > best { best = candidate }
		}
		profit[rod] = best
	}
	return profit[n]
}
