module bidirectional_fm_index

struct Index {
	cumulative [5]int
	bwt [65]int
}

fn suffix_less(s &i64, total int, a0 int, b0 int) bool {
	mut a := a0
	mut b := b0
	for a < total && b < total {
		x := unsafe { s[a] }
		y := unsafe { s[b] }
		if x != y { return x < y }
		a++
		b++
	}
	return a == total && b != total
}

fn build_index(s &i64, total int) Index {
	mut result := Index{}
	mut suffixes := [65]int{}
	mut frequency := [5]int{}
	for i in 0 .. total { suffixes[i] = i }
	for i in 1 .. total {
		key := suffixes[i]
		mut j := i
		for j > 0 && suffix_less(s, total, key, suffixes[j - 1]) {
			suffixes[j] = suffixes[j - 1]
			j--
		}
		suffixes[j] = key
	}
	for i in 0 .. total {
		result.bwt[i] = unsafe { s[(suffixes[i] + total - 1) % total] }
		frequency[result.bwt[i]]++
	}
	mut seen := 0
	for symbol in 0 .. 5 {
		result.cumulative[symbol] = seen
		seen += frequency[symbol]
	}
	return result
}

fn rank_before(index Index, end_at int, symbol int) int {
	mut count := 0
	for i in 0 .. end_at { if index.bwt[i] == symbol { count++ } }
	return count
}

@[export: 'bidirectional_fm_index']
pub fn bidirectional_fm_index(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > 195 { return -1 }
	n0 := unsafe { input[0] }
	q0 := unsafe { input[1] }
	if n0 < 0 || n0 > 64 || q0 < 0 || q0 > 64 { return -1 }
	n := int(n0)
	q := int(q0)
	if length != usize(2 + n + 2 * q) { return -1 }
	mut forward_text := [65]i64{}
	mut reverse_text := [65]i64{}
	for i in 0 .. n {
		symbol := unsafe { input[2 + i] }
		if symbol < 1 || symbol > 4 { return -1 }
		forward_text[i] = symbol
		reverse_text[n - 1 - i] = symbol
	}
	forward_text[n] = 0
	reverse_text[n] = 0
	for op in 0 .. q {
		side := unsafe { input[2 + n + 2 * op] }
		symbol := unsafe { input[3 + n + 2 * op] }
		if (side != 0 && side != 1) || symbol < 1 || symbol > 4 { return -1 }
	}
	total := n + 1
	forward := build_index(&forward_text[0], total)
	reverse := build_index(&reverse_text[0], total)
	mut fl := 0
	mut fr := total
	mut rl := 0
	mut rr := total
	mut checksum := i64(0)
	for op in 0 .. q {
		side := int(unsafe { input[2 + n + 2 * op] })
		symbol := int(unsafe { input[3 + n + 2 * op] })
		old_fl := fl
		old_fr := fr
		old_rl := rl
		old_rr := rr
		if side == 0 {
			fl = forward.cumulative[symbol] + rank_before(forward, old_fl, symbol)
			fr = forward.cumulative[symbol] + rank_before(forward, old_fr, symbol)
			mut start := old_rl
			for smaller in 0 .. symbol { start += rank_before(forward, old_fr, smaller) - rank_before(forward, old_fl, smaller) }
			count := rank_before(forward, old_fr, symbol) - rank_before(forward, old_fl, symbol)
			rl = start
			rr = start + count
		} else {
			rl = reverse.cumulative[symbol] + rank_before(reverse, old_rl, symbol)
			rr = reverse.cumulative[symbol] + rank_before(reverse, old_rr, symbol)
			mut start := old_fl
			for smaller in 0 .. symbol { start += rank_before(reverse, old_rr, smaller) - rank_before(reverse, old_rl, smaller) }
			count := rank_before(reverse, old_rr, symbol) - rank_before(reverse, old_rl, symbol)
			fl = start
			fr = start + count
		}
		checksum += i64(op + 1) * i64(fr - fl)
	}
	return checksum
}
