package k_repetition_block_head_pair_pass

import "core:c"

MAX_N :: 24
MAX_K :: 3
MAX_INPUT :: 27
MAX_CONTEXT :: 48
MAX_FACTORS :: 25
MAX_PERIODS :: 13
BIT_WORDS :: 117
MAX_OUTPUT :: 39112

Pass :: struct {
	text: [MAX_N]int,
	starts: [MAX_FACTORS]int,
	ends: [MAX_FACTORS]int,
	seen: [BIT_WORDS]u64,
	n, budget, factor_count: int,
}

right_extend :: proc(w: []int, center, period, allowed: int) -> int {
	left := center - period
	limit := min(len(w)-left, len(w)-center)
	errors := 0
	for d := 0; d < limit; d += 1 {
		if w[left+d] != w[center+d] {
			errors += 1
			if errors > allowed do return d
		}
	}
	return limit
}

left_extend :: proc(w: []int, center, period, allowed: int) -> int {
	limit := center - period
	errors := 0
	for d := 0; d < limit; d += 1 {
		if w[center-period-1-d] != w[center-1-d] {
			errors += 1
			if errors > allowed do return d
		}
	}
	return limit
}

mark :: proc(s: ^Pass, base, size, center, next, lo, hi, period: int) {
	if hi >= size || hi-lo+1 < 2*period do return
	if lo > center+1 || hi+1 < center do return
	if lo <= next+1 && hi+1 >= next do return
	start, finish := base+lo, base+hi
	if finish >= s.n do return
	index := (start*MAX_N+finish)*MAX_PERIODS+period
	s.seen[index/64] |= u64(1) << u64(index%64)
}

at_head :: proc(s: ^Pass, w: []int, base, center, next: int) {
	if center <= 0 || center+1 >= len(w) do return
	for period := 1; period <= center; period += 1 {
		for split := 0; split <= s.budget; split += 1 {
			f := right_extend(w, center, period, split)
			b := left_extend(w, center, period, s.budget-split)
			if f <= period && f+b >= period do mark(s, base, len(w), center, next,
				center-period-b, center+f-1, period)
		}
	}
	var reversed: [MAX_CONTEXT]int
	for i := 0; i < len(w); i += 1 do reversed[i] = w[len(w)-1-i]
	rc := len(w)-1-center
	for period := 1; period <= rc; period += 1 {
		for split := 0; split <= s.budget; split += 1 {
			f := right_extend(reversed[:len(w)], rc, period, split)
			b := left_extend(reversed[:len(w)], rc, period, s.budget-split)
			if f <= period && f+b >= period {
				rs, re := rc-period-b, rc+f-1
				mark(s, base, len(w), center, next, len(w)-1-re, len(w)-1-rs, period)
			}
		}
	}
}

factorize :: proc(s: ^Pass) {
	pos := 0
	for pos < s.n {
		best := 0
		for earlier := 0; earlier < pos; earlier += 1 {
			matched := 0
			for pos+matched < s.n && earlier+matched < s.n &&
				s.text[earlier+matched] == s.text[pos+matched] do matched += 1
			best = max(best, matched)
		}
		s.starts[s.factor_count] = pos
		finish := min(s.n, pos+best+1)
		s.ends[s.factor_count] = finish
		s.factor_count += 1
		pos = finish
	}
}

run_heads :: proc(s: ^Pass) {
	block := s.budget+2
	blocks := (s.factor_count+block-1)/block
	for bi := 0; bi+1 < blocks; bi += 1 {
		first := bi*block
		first_end := min(s.factor_count, first+block)
		second_end := min(s.factor_count, first_end+block)
		head, next := s.ends[first_end-1]-1, s.ends[second_end-1]-1
		pair_start, pair_end := s.starts[first], s.ends[second_end-1]
		span := pair_end-pair_start
		base := max(0, pair_start-span)
		size := pair_end-base
		var local: [MAX_CONTEXT]int
		for i := 0; i < size; i += 1 do local[i] = s.text[base+i]
		at_head(s, local[:size], base, head-base, next-base)
	}
}

put_i64 :: proc(output: [^]u8, offset: int, value: u64) {
	for b := 0; b < 8; b += 1 do output[offset+b] = u8((value >> u64(8*b)) & 255)
}

@(export)
k_repetition_block_head_pair_pass :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT) do return -1
	nv, kv := input[0], input[1]
	if nv < 1 || nv > MAX_N || kv < 0 || kv > MAX_K do return -1
	n, budget := int(nv), int(kv)
	if length != c.size_t(n+2) do return -1
	state: Pass = {}
	state.n, state.budget = n, budget
	for i := 0; i < n; i += 1 {
		if input[i+2] < 0 || input[i+2] > 4 do return -1
		state.text[i] = int(input[i+2])
	}
	for i := 0; i+1 < n; i += 1 do if state.text[i] == state.text[n-1] do return -1
	factorize(&state)
	run_heads(&state)
	count := 0
	for start := 0; start < n; start += 1 {
		for size := 2; size <= n-start; size += 1 {
			finish := start+size-1
			for period := 1; period <= size/2; period += 1 {
				index := (start*MAX_N+finish)*MAX_PERIODS+period
				if state.seen[index/64] & (u64(1) << u64(index%64)) != 0 do count += 1
			}
		}
	}
	written := 8+count*32
	if written > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(written) do return -2
	put_i64(output, 0, u64(count))
	offset := 8
	for start := 0; start < n; start += 1 {
		for size := 2; size <= n-start; size += 1 {
			finish := start+size-1
			for period := 1; period <= size/2; period += 1 {
				index := (start*MAX_N+finish)*MAX_PERIODS+period
				if state.seen[index/64] & (u64(1) << u64(index%64)) == 0 do continue
				errors := 0
				for i := start; i <= finish-period; i += 1 do if state.text[i] != state.text[i+period] do errors += 1
				put_i64(output, offset, u64(start)); offset += 8
				put_i64(output, offset, u64(size)); offset += 8
				put_i64(output, offset, u64(period)); offset += 8
				put_i64(output, offset, u64(errors)); offset += 8
			}
		}
	}
	return i64(written)
}
