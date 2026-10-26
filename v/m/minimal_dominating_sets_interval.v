module minimal_dominating_sets_interval

fn intervals_intersect(s &i64, e &i64, a int, b int) bool {
	return unsafe { s[a] <= e[b] && s[b] <= e[a] }
}

@[export: 'minimal_dominating_sets_interval']
pub fn minimal_dominating_sets_interval(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 3 || length > 25 { return -1 }
	n0 := unsafe { input[0] }
	if n0 < 1 || n0 > 12 || length != usize(1 + 2*n0) { return -1 }
	n := int(n0); mut s := [12]i64{}; mut e := [12]i64{}
	mut min_end := i64(0); mut max_start := i64(0)
	for i in 0 .. n {
		s[i] = unsafe { input[1+2*i] }; e[i] = unsafe { input[2+2*i] }
		if s[i] < -100 || s[i] > 100 || e[i] < -100 || e[i] > 100 || s[i] >= e[i] { return -1 }
		if i > 0 && s[i-1] >= s[i] { return -1 }
		if i == 0 || e[i] < min_end { min_end = e[i] }
		if i == 0 || s[i] > max_start { max_start = s[i] }
		for j in 0 .. i { if s[i] == s[j] || s[i] == e[j] || e[i] == s[j] || e[i] == e[j] { return -1 } }
	}
	if output == nil || output_capacity < 8 { return -2 }
	mut has_next := [12]bool{}; mut ncs := [12]i64{}; mut nce := [12]i64{}; mut p_single := [12]i64{}
	for i in 0 .. n {
		p_single[i] = 0x7fffffffffffffff
		for z in 0 .. n {
			if intervals_intersect(&s[0], &e[0], i, z) && e[z] < p_single[i] { p_single[i] = e[z] }
			if s[z] > e[i] { if !has_next[i] || s[z] < ncs[i] { ncs[i] = s[z] }; if !has_next[i] || e[z] < nce[i] { nce[i] = e[z] }; has_next[i] = true }
		}
	}
	mut valid := [12][12]bool{}; mut p_pair := [12][12]i64{}
	for i in 0 .. n { for j in i+1 .. n {
		p_pair[i][j] = 0x7fffffffffffffff
		for z in 0 .. n { if intervals_intersect(&s[0],&e[0],j,z) && !intervals_intersect(&s[0],&e[0],i,z) && e[z] < p_pair[i][j] { p_pair[i][j]=e[z] } }
		valid[i][j] = has_next[i] && p_single[i] < s[j] && s[j] <= nce[i] && e[j] >= ncs[i]
	} }
	mut ways := [12][12]i64{}
	for j in 1 .. n { for i in 0 .. j {
		if !valid[i][j] { continue }; if s[i] <= min_end { ways[i][j]++ }
		for k in j+1 .. n { if valid[j][k] && p_pair[i][j] < s[k] && s[k] <= nce[j] { ways[j][k] += ways[i][j] } }
	} }
	mut count := i64(0)
	for i in 0 .. n { if s[i] <= min_end && e[i] >= max_start { count++ } }
	for i in 0 .. n { for j in i+1 .. n { if e[j] >= max_start { count += ways[i][j] } } }
	bits := u64(count)
	unsafe { for b in 0 .. 8 { output[b] = u8((bits >> (8*b)) & 0xff) } }
	return 8
}
