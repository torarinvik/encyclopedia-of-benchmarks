module nysiis_encoder

fn vowel(c u8) bool { return c == `A` || c == `E` || c == `I` || c == `O` || c == `U` }
fn matches(s []u8, n int, at int, p string) bool {
	if at + p.len > n { return false }
	for i in 0 .. p.len { if s[at+i] != p[i] { return false } }
	return true
}
fn replace_at(mut s []u8, mut n int, at int, old int, to string) {
	if to.len > old {
		mut i := n
		for i > at + old { i--; s[i-old+to.len] = s[i] }
	} else {
		for i in at + old .. n { s[i-old+to.len] = s[i] }
	}
	for i in 0 .. to.len { s[at+i] = to[i] }
	n = n - old + to.len
}

@[export: 'nysiis_encoder']
pub fn nysiis_encoder(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 2 || length > 65 { return -1 }
	count := unsafe { values[0] }
	if count < 1 || count > 64 || length != usize(count) + 1 { return -1 }
	mut s := []u8{len: 256}
	mut n := 0
	for i in 0 .. int(count) {
		mut c := unsafe { values[i+1] }
		if c == 32 { continue }
		if c >= 97 && c <= 122 { c -= 32 }
		if c < 65 || c > 90 { return -1 }
		s[n] = u8(c); n++
	}
	if n == 0 { return -1 }
	starts := [[2]string{'MAC','MCC'},['KN','NN'],['K','C'],['PH','FF'],['PF','FF'],['SCH','SSS']]
	for pair in starts { if matches(s,n,0,pair[0]) { replace_at(mut s,mut n,0,pair[0].len,pair[1]); break } }
	ends := [[2]string{'EE','Y'},['IE','Y'],['DT','D'],['RT','D'],['NT','D'],['ND','D']]
	for pair in ends { if n >= pair[0].len && matches(s,n,n-pair[0].len,pair[0]) { replace_at(mut s,mut n,n-pair[0].len,pair[0].len,pair[1]); break } }
	rules := [[2]string{'EV','AF'},['E','A'],['I','A'],['O','A'],['U','A'],['Q','G'],['Z','S'],['M','N'],['KN','NN'],['K','C'],['SCH','SSS'],['PH','FF']]
	mut i := 1
	for i < n {
		mut changed := false
		for pair in rules { if matches(s,n,i,pair[0]) { replace_at(mut s,mut n,i,pair[0].len,pair[1]); changed = true; break } }
		if !changed {
			if s[i] == `H` && (!vowel(s[i-1]) || (i+1<n && !vowel(s[i+1]))) { s[i] = s[i-1] }
			else if s[i] == `W` && vowel(s[i-1]) { s[i] = s[i-1] }
		}
		i++
	}
	mut w := 0
	for j in 0 .. n { if j == 0 || s[j] != s[j-1] { s[w] = s[j]; w++ } }
	n = w
	if n > 0 && s[n-1] == `S` { n-- } else if n >= 2 && s[n-2] == `A` && s[n-1] == `Y` { s[n-2] = `Y`; n-- } else if n > 0 && s[n-1] == `A` { n-- }
	if usize(n) > capacity || (n > 0 && isnil(output)) { return -2 }
	for j in 0 .. n { unsafe { output[j] = s[j] } }
	return i64(n)
}
