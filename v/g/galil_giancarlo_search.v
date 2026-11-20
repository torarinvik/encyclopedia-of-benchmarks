module galil_giancarlo_search

const max_text = 4096
const max_pattern = 128
const max_input = 4227
const tables = 130

fn preprocess(pattern []i64, m int, mut order [tables]i64, mut next_pos [tables]i64,
	mut shift [tables]i64) i64 {
	mut hmax := [tables]i64{}
	mut kmin := [tables]i64{}
	mut prefix := [tables]i64{}
	mut rmin := [tables]i64{}
	mut i := i64(1)
	mut k := i64(1)
	for k <= i64(m) {
		for pattern[int(i)] == pattern[int(i-k)] { i++ }
		hmax[int(k)] = i
		mut q := k+1
		for hmax[int(q-k)]+k < i { hmax[int(q)] = hmax[int(q-k)]+k; q++ }
		k=q
		if k == i+1 { i=k }
	}
	for x := m; x >= 1; x-- { if hmax[x] < i64(m) { kmin[int(hmax[x])] = i64(x) } }
	mut r := i64(m)
	for x := m-1; x >= 0; x-- {
		if hmax[x+1] == i64(m) { r=i64(x+1) }
		if kmin[x] == 0 { rmin[x]=r }
	}
	mut split := -1
	r=i64(m)
	for x in 0 .. m {
		if kmin[x] == 0 { r--; order[int(r)]=i64(x) } else { split++; order[split]=i64(x) }
	}
	for x in 0 .. split+1 { shift[x]=kmin[int(order[x])] }
	for x in split+1 .. m { shift[x]=rmin[int(order[x])] }
	shift[m]=rmin[0]
	mut count := i64(0)
	for x in 0 .. m { prefix[x]=count; if kmin[x]>0 { count++ } }
	for x in 0 .. split+1 { pos:=int(order[x]); next_pos[x]=prefix[int(order[x]-kmin[pos])] }
	for x in split+1 .. m { next_pos[x]=prefix[m-int(rmin[int(order[x])])] }
	next_pos[m]=prefix[m-int(rmin[int(order[m-1])])]
	return i64(split)
}

fn gg_search(text []i64, pattern []i64, n int, m int) i64 {
	mut ell := 0
	for ell+1 < m && pattern[ell+1] == pattern[0] { ell++ }
	mut matches := i64(0)
	mut offset_sum := i64(0)
	mut offset_xor := i64(0)
	if ell == m-1 {
		mut run := 0
		for position in 0 .. n {
			if text[position] == pattern[0] { run++ } else { run=0 }
			if run >= m { start:=i64(position+1-m); matches++; offset_sum+=start; offset_xor^=start }
		}
		return (matches<<36)|(offset_sum<<12)|offset_xor
	}
	mut order := [tables]i64{}
	mut next_pos := [tables]i64{}
	mut shift := [tables]i64{}
	nd := preprocess(pattern,m,mut order,mut next_pos,mut shift)
	if n < m { return 0 }
	mut i := i64(0)
	mut j := i64(0)
	mut last := i64(-1)
	mut heavy := false
	for j <= i64(n-m) {
		if heavy && i == 0 {
			mut k := last-j+1
			for int(j+k) < n && pattern[0] == text[int(j+k)] { k++ }
			if k <= i64(ell) || int(j+k) >= n || pattern[ell+1] != text[int(j+k)] {
				i=0; j+=k+1; last=j-1
			} else { i=1; last=j+k; j=last-i64(ell+1) }
		} else {
			for i < i64(m) && last < j+order[int(i)] && pattern[int(order[int(i)])] == text[int(j+order[int(i)])] { i++ }
			if i >= i64(m) || last >= j+order[int(i)] { matches++; offset_sum+=j; offset_xor^=j; i=i64(m) }
			if i > nd { last=j+i64(m)-1 }
			j+=shift[int(i)]; i=next_pos[int(i)]
		}
		heavy=j<=last
	}
	return (matches<<36)|(offset_sum<<12)|offset_xor
}

@[export: 'galil_giancarlo_search']
pub fn galil_giancarlo_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		nv,mv := input[0],input[1]
		if nv < 0 || nv > max_text || mv < 1 || mv > max_pattern { return -1 }
		n,m := int(nv),int(mv)
		if length != usize(2+n+m) { return -1 }
		mut text := [max_text]i64{}
		mut pattern := [tables]i64{}
		for i in 0 .. n { symbol:=input[2+i]; if symbol<0 || symbol>3 { return -1 }; text[i]=symbol }
		for i in 0 .. m { symbol:=input[2+n+i]; if symbol<0 || symbol>3 { return -1 }; pattern[i]=symbol }
		pattern[m]=4
		return gg_search(text[..n],pattern[..m+1],n,m)
	}
}
