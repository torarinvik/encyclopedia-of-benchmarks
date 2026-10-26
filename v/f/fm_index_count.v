module fm_index_count

fn suffix_less(s &i64, n int, a0 int, b0 int) bool {
	mut a := a0
	mut b := b0
	for a < n && b < n {
		x := unsafe { s[a] }; y := unsafe { s[b] }
		if x != y { return x < y }
		a++; b++
	}
	return a == n && b != n
}

@[export: 'fm_index_count']
pub fn fm_index_count(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 4 || length > 42 { return -1 }
	n0 := unsafe { input[0] }
	if n0 < 1 || n0 > 32 || length < usize(n0 + 3) { return -1 }
	n := int(n0); m_at := n + 1; m0 := unsafe { input[m_at] }
	if m0 < 1 || m0 > 8 || length != usize(n + m0 + 2) { return -1 }
	m := int(m0); total := n + 1
	mut s := [33]i64{}; mut pattern := [8]i64{}
	for i in 0 .. n {
		x := unsafe { input[1+i] }; if x < 1 || x > 4 { return -1 }; s[i] = x
	}
	for i in 0 .. m {
		x := unsafe { input[m_at+1+i] }; if x < 1 || x > 4 { return -1 }; pattern[i] = x
	}
	s[n] = 0
	if output == nil || output_capacity < 8 { return -2 }
	mut sa := [33]int{}
	for i in 0 .. total { sa[i] = i }
	for i in 1 .. total {
		key := sa[i]; mut j := i
		for j > 0 && suffix_less(&s, total, key, sa[j-1]) { sa[j] = sa[j-1]; j-- }
		sa[j] = key
	}
	mut bwt := [33]int{}; mut freq := [5]int{}
	for i in 0 .. total { bwt[i] = s[(sa[i]+total-1)%total]; freq[bwt[i]]++ }
	mut c := [5]int{}; mut sum := 0
	for x in 0 .. 5 { c[x] = sum; sum += freq[x] }
	mut left := 0; mut right := total
	for k in 0 .. m {
		symbol := int(pattern[m-1-k]); mut rl := 0; mut rr := 0
		for i in 0 .. left { if bwt[i] == symbol { rl++ } }
		for i in 0 .. right { if bwt[i] == symbol { rr++ } }
		left = c[symbol] + rl; right = c[symbol] + rr
		if left == right { break }
	}
	count := u64(right-left)
	unsafe { for i in 0 .. 8 { output[i] = u8((count >> (8*i)) & 0xff) } }
	return 8
}
