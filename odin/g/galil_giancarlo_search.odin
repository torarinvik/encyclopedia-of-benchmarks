package galil_giancarlo_search

import "core:c"

MAX_TEXT :: 4096
MAX_PATTERN :: 128
MAX_INPUT :: 4227
TABLES :: 130

preprocess :: proc(pattern: []i64, m: int, order, next, shift: []i64) -> i64 {
	var hmax, kmin, prefix, rmin: [TABLES]i64
	i, k := i64(1), i64(1)
	for i64(m) >= k {
		for pattern[int(i)] == pattern[int(i-k)] { i += 1 }
		hmax[int(k)] = i
		q := k+1
		for hmax[int(q-k)]+k < i { hmax[int(q)] = hmax[int(q-k)]+k; q += 1 }
		k = q
		if k == i+1 { i = k }
	}
	for x := m; x >= 1; x -= 1 { if hmax[x] < i64(m) { kmin[int(hmax[x])] = i64(x) } }
	r := i64(m)
	for x := m-1; x >= 0; x -= 1 {
		if hmax[x+1] == i64(m) { r=i64(x+1) }
		if kmin[x] == 0 { rmin[x]=r }
	}
	split := -1
	r=i64(m)
	for x := 0; x < m; x += 1 {
		if kmin[x] == 0 { r-=1; order[int(r)]=i64(x) }
		else { split+=1; order[split]=i64(x) }
	}
	for x := 0; x <= split; x += 1 { shift[x]=kmin[int(order[x])] }
	for x := split+1; x < m; x += 1 { shift[x]=rmin[int(order[x])] }
	shift[m]=rmin[0]
	count := i64(0)
	for x := 0; x < m; x += 1 { prefix[x]=count; if kmin[x]>0 { count+=1 } }
	for x := 0; x <= split; x += 1 { pos:=int(order[x]); next[x]=prefix[int(order[x]-kmin[pos])] }
	for x := split+1; x < m; x += 1 { next[x]=prefix[m-int(rmin[int(order[x])])] }
	next[m]=prefix[m-int(rmin[int(order[m-1])])]
	return i64(split)
}

search :: proc(text, pattern: []i64, n, m: int) -> i64 {
	ell := 0
	for ell+1 < m && pattern[ell+1] == pattern[0] { ell += 1 }
	matches, sum, xor_sum := i64(0), i64(0), i64(0)
	if ell == m-1 {
		run := 0
		for pos := 0; pos < n; pos += 1 {
			if text[pos] == pattern[0] { run+=1 } else { run=0 }
			if run >= m { start:=i64(pos+1-m); matches+=1; sum+=start; xor_sum^=start }
		}
		return (matches<<36)|(sum<<12)|xor_sum
	}
	var order_buf, next_buf, shift_buf: [TABLES]i64
	order, next, shift := order_buf[:], next_buf[:], shift_buf[:]
	nd := preprocess(pattern,m,order,next,shift)
	if n < m { return 0 }
	i,j,last := i64(0),i64(0),i64(-1)
	heavy := false
	for j <= i64(n-m) {
		if heavy && i == 0 {
			k := last-j+1
			for int(j+k) < n && pattern[0] == text[int(j+k)] { k+=1 }
			if k <= i64(ell) || int(j+k) >= n || pattern[ell+1] != text[int(j+k)] {
				i=0; j+=k+1; last=j-1
			} else { i=1; last=j+k; j=last-i64(ell+1) }
		} else {
			for i < i64(m) && last < j+order[int(i)] && pattern[int(order[int(i)])] == text[int(j+order[int(i)])] { i+=1 }
			if i >= i64(m) || last >= j+order[int(i)] { matches+=1; sum+=j; xor_sum^=j; i=i64(m) }
			if i > nd { last=j+i64(m)-1 }
			j+=shift[int(i)]; i=next[int(i)]
		}
		heavy=j<=last
	}
	return (matches<<36)|(sum<<12)|xor_sum
}

@(export)
galil_giancarlo_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv,mv := input[0],input[1]
	if nv < 0 || nv > MAX_TEXT || mv < 1 || mv > MAX_PATTERN do return -1
	n,m := int(nv),int(mv)
	if length != c.size_t(2+n+m) do return -1
	var text_buf: [MAX_TEXT]i64
	var pattern_buf: [TABLES]i64
	for i := 0; i < n; i += 1 { symbol:=input[2+i]; if symbol<0 || symbol>3 do return -1; text_buf[i]=symbol }
	for i := 0; i < m; i += 1 { symbol:=input[2+n+i]; if symbol<0 || symbol>3 do return -1; pattern_buf[i]=symbol }
	pattern_buf[m]=4
	return search(text_buf[:n],pattern_buf[:m+1],n,m)
}
