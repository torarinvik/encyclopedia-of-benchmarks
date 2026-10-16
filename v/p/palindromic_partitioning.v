@[export: 'palindromic_partitioning']
pub fn palindromic_partitioning(v &i64, n usize) i64 {
	unsafe {
		if v == nil || n < 2 || n > 65 || v[0] < 1 || v[0] > 64 || n != usize(v[0] + 1) { return -1 }
		m := int(v[0]); mut p := [][]bool{len: 64, init: []bool{len: 64}}; mut cuts := []i64{len: 64, init: 0}
		for ending in 0 .. m {
			x := v[ending + 1]; if x < 0 || x > 127 { return -1 }
			for start in 0 .. ending + 1 { p[start][ending] = v[start + 1] == x && (ending - start < 2 || p[start + 1][ending - 1]) }
		}
		for ending in 0 .. m {
			if p[0][ending] { cuts[ending] = 0 } else {
				cuts[ending] = 64
				for start in 1 .. ending + 1 { if p[start][ending] && cuts[start - 1] + 1 < cuts[ending] { cuts[ending] = cuts[start - 1] + 1 } }
			}
		}
		return cuts[m - 1]
	}
}
