module main

@[export: 'jaro_similarity']
pub fn jaro_similarity(v &i64, n usize) f64 {
	if n < 2 || n > 66 { return -1.0e300 }
	if v[0] < 0 || v[0] > 32 { return -1.0e300 }
	n1 := int(v[0]); p := 1 + n1
	if p >= n || v[p] < 0 || v[p] > 32 { return -1.0e300 }
	n2 := int(v[p])
	if n1 < n2 || n != usize(p + 1 + n2) { return -1.0e300 }
	for i in 0 .. n1 { if v[1 + i] < 0 || v[1 + i] > 127 { return -1.0e300 } }
	for i in 0 .. n2 { if v[p + 1 + i] < 0 || v[p + 1 + i] > 127 { return -1.0e300 } }
	mut equal := n1 == n2
	for i in 0 .. n1 { if v[1 + i] != v[p + 1 + i] { equal = false } }
	if equal { return 1.0 }
	if n2 == 0 { return 0.0 }
	radius := max(n1 / 2 - 1, 0)
	mut m1 := []bool{len: 32}; mut m2 := []bool{len: 32}
	mut matches := 0
	for i in 0 .. n1 {
		start := max(i - radius, 0); finish := min(i + radius, n2 - 1)
		if start <= finish {
			for j in start .. finish + 1 {
				if v[1 + i] == v[p + 1 + j] && !m2[j] { matches++; m1[i] = true; m2[j] = true; break }
			}
		}
	}
	if matches == 0 { return 0.0 }
	mut trans := 0; mut j := 0
	for i in 0 .. n1 {
		if m1[i] { for !m2[j] { j++ }; if v[1 + i] != v[p + 1 + j] { trans++ }; j++ }
	}
	trans /= 2
	return (f64(matches) / f64(n1) + f64(matches) / f64(n2) + f64(matches - trans) / f64(matches)) / 3.0
}
