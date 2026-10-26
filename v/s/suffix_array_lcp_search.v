module main

const max_n = 32
const max_m = 16
const max_input = 50
const max_output = 264

fn suffix_cmp(text [32]i64, a int, b int, n int) int {
	mut k := 0
	for a+k < n && b+k < n {
		if text[a+k] < text[b+k] { return -1 }
		if text[a+k] > text[b+k] { return 1 }
		k++
	}
	if a+k == n && b+k == n { return 0 }
	if a+k == n { return -1 }
	return 1
}

fn pattern_cmp(text [32]i64, start int, n int, pattern [16]i64,
	m int, offset int, prefix_equal bool, mut matched &int) int {
	matched = offset
	for matched < m && start+matched < n && text[start+matched] == pattern[matched] { matched++ }
	if matched == m {
		if prefix_equal || start+matched == n { return 0 }
		return 1
	}
	if start+matched == n { return -1 }
	if text[start+matched] < pattern[matched] { return -1 }
	return 1
}

fn build_intervals(n int, lcp [32]int, mut left_q [1024]int, mut right_q [1024]int) {
	mut lo_stack := [64]int{}
	mut hi_stack := [64]int{}
	mut top := 1
	lo_stack[0] = 0
	hi_stack[0] = n-1
	for top > 0 {
		top--
		lo, hi := lo_stack[top], hi_stack[top]
		if hi-lo < 2 { continue }
		mid := (lo+hi+1)/2
		mut q := n+1
		for k := lo; k < mid; k++ { if lcp[k] < q { q = lcp[k] } }
		left_q[lo*max_n+hi] = q
		q = n+1
		for k := mid; k < hi; k++ { if lcp[k] < q { q = lcp[k] } }
		right_q[lo*max_n+hi] = q
		if hi-mid >= 2 { lo_stack[top] = mid; hi_stack[top] = hi; top++ }
		if mid-lo >= 2 { lo_stack[top] = lo; hi_stack[top] = mid; top++ }
	}
}

fn bound(text [32]i64, n int, pattern [16]i64, m int, suffix [32]int,
	left_q [1024]int, right_q [1024]int, prefix_equal bool) int {
	mut l, r := 0, 0
	first := pattern_cmp(text, suffix[0], n, pattern, m, 0, prefix_equal, mut l)
	if first > 0 || (!prefix_equal && first == 0) { return 0 }
	last := pattern_cmp(text, suffix[n-1], n, pattern, m, 0, prefix_equal, mut r)
	if last < 0 || (prefix_equal && last == 0) { return n }
	mut lo, hi := 0, n-1
	for hi-lo > 1 {
		mid := (lo+hi+1)/2
		mut cmp, matched := 0, 0
		if l == r {
			cmp = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal, mut matched)
			if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched } else { lo = mid; l = matched }
		} else if l > r {
			q := left_q[lo*max_n+hi]
			if l < q { lo = mid } else if l > q { hi = mid; r = q } else {
				cmp = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal, mut matched)
				if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched } else { lo = mid; l = matched }
			}
		} else {
			q := right_q[lo*max_n+hi]
			if r < q { hi = mid } else if r > q { lo = mid; l = q } else {
				cmp = pattern_cmp(text, suffix[mid], n, pattern, m, r, prefix_equal, mut matched)
				if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched } else { lo = mid; l = matched }
			}
		}
	}
	return hi
}

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for b in 0 .. 8 { output[offset+b] = u8((bits >> (b*8)) & 255) } }
}

@[export: 'suffix_array_lcp_search']
pub fn suffix_array_lcp_search(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 3 || length > max_input { return -1 }
		if values[0] < 1 || values[0] > max_n { return -1 }
		n := int(values[0])
		if length < usize(n+2) || values[n+1] < 1 || values[n+1] > max_m { return -1 }
		m := int(values[n+1])
		if length != usize(n+m+2) { return -1 }
		mut text := [32]i64{}
		mut pattern := [16]i64{}
		mut suffix := [32]int{}
		mut lcp := [32]int{}
		mut left_q := [1024]int{}
		mut right_q := [1024]int{}
		for i in 0 .. n {
			text[i] = values[1+i]
			if text[i] < 0 || text[i] > 127 { return -1 }
			suffix[i] = i
		}
		for i in 0 .. m {
			pattern[i] = values[n+2+i]
			if pattern[i] < 0 || pattern[i] > 127 { return -1 }
		}
		for i := 1; i < n; i++ {
			key := suffix[i]
			mut j := i
			for j > 0 && suffix_cmp(text,key,suffix[j-1],n) < 0 { suffix[j] = suffix[j-1]; j-- }
			suffix[j] = key
		}
		for i := 0; i+1 < n; i++ {
			a,b := suffix[i],suffix[i+1]
			mut k := 0
			for a+k < n && b+k < n && text[a+k] == text[b+k] { k++ }
			lcp[i] = k
		}
		build_intervals(n,lcp,mut left_q,mut right_q)
		first := bound(text,n,pattern,m,suffix,left_q,right_q,false)
		last := bound(text,n,pattern,m,suffix,left_q,right_q,true)
		count := last-first
		bytes := 8*(count+1)
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [264]u8{}
		put_i64(mut staged[0],0,i64(count))
		for i in 0 .. count { put_i64(mut staged[0],8*(i+1),i64(suffix[first+i])) }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
