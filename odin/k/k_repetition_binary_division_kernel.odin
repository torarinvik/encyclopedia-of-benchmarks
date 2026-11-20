package k_repetition_binary_division_kernel

import "core:c"

MAX_N :: 32
MAX_K :: 3
MAX_INPUT :: 35
MAX_PERIODS :: 17
BIT_WORDS :: 272
MAX_FACTORS :: 33
MAX_OUTPUT :: 91400

Search :: struct {
	text: [MAX_N]int,
	n, budget, factor_count: int,
	starts: [MAX_FACTORS]int,
	ends: [MAX_FACTORS]int,
	seen: [BIT_WORDS]u64,
}

lp :: proc(text: []int, lo, hi, center, period, allowed: int) -> int {
	left := center - period
	limit := min(hi-left, hi-center)
	errors := 0
	for j := 0; j < limit; j += 1 {
		if text[left+j] != text[center+j] {
			errors += 1
			if errors > allowed do return j
		}
	}
	return limit
}

ls :: proc(text: []int, lo, center, period, allowed: int) -> int {
	limit := min(center-period-lo, center-lo)
	errors := 0
	for j := 0; j < limit; j += 1 {
		if text[center-period-1-j] != text[center-1-j] {
			errors += 1
			if errors > allowed do return j
		}
	}
	return limit
}

mark :: proc(s: ^Search, lo, last_head, local_start, local_end, period: int) {
	start, finish := lo+local_start, lo+local_end
	if start <= lo || finish >= s.n || finish-start+1 < 2*period do return
	if start <= last_head+1 && finish+1 >= last_head do return
	index := (start*MAX_N+finish)*MAX_PERIODS+period
	s.seen[index/64] |= u64(1) << u64(index%64)
}

at_center :: proc(s: ^Search, text: []int, lo, center, last_head: int) {
	center_local := center - lo
	if center_local <= 0 || center_local+1 >= len(text) do return
	for period := 1; period <= center_local; period += 1 {
		for k := 0; k <= s.budget; k += 1 {
			forward := lp(text, 0, len(text), center_local, period, k)
			backward := ls(text, 0, center_local, period, s.budget-k)
			if forward <= period && forward+backward >= period {
				mark(s, lo, last_head, center_local-period-backward, center_local+forward-1, period)
			}
		}
	}
	var reversed: [MAX_N]int
	for i := 0; i < len(text); i += 1 do reversed[i] = text[len(text)-1-i]
	rc := len(text)-1-center_local
	for period := 1; period <= rc; period += 1 {
		for k := 0; k <= s.budget; k += 1 {
			forward := lp(reversed[:len(text)], 0, len(text), rc, period, k)
			backward := ls(reversed[:len(text)], 0, rc, period, s.budget-k)
			if forward <= period && forward+backward >= period {
				rs, re := rc-period-backward, rc+forward-1
				mark(s, lo, last_head, len(text)-1-re, len(text)-1-rs, period)
			}
		}
	}
}

divide :: proc(s: ^Search, first, last: int) {
	if first >= last do return
	middle := first + (last-first)/2
	lo, hi := s.starts[first], s.ends[last]
	center, last_head := s.ends[middle]-1, s.ends[last]-1
	at_center(s, s.text[lo:hi], lo, center, last_head)
	divide(s, first, middle)
	divide(s, middle+1, last)
}

encode_i64 :: proc(output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 do output[offset+byte] = u8((value >> u64(8*byte)) & 255)
}

@(export)
k_repetition_binary_division_kernel :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT) do return -1
	nv, kv := input[0], input[1]
	if nv < 1 || nv > MAX_N || kv < 0 || kv > MAX_K do return -1
	n, budget := int(nv), int(kv)
	if length != c.size_t(n+2) do return -1
	state: Search = {}
	state.n, state.budget = n, budget
	for i := 0; i < n; i += 1 {
		if input[i+2] < 0 || input[i+2] > 4 do return -1
		state.text[i] = int(input[i+2])
	}
	for i := 0; i+1 < n; i += 1 do if state.text[i] == state.text[n-1] do return -1

	pos := 0
	for pos < n {
		best := 0
		for earlier := 0; earlier < pos; earlier += 1 {
			matched := 0
			for pos+matched < n && earlier+matched < n && state.text[earlier+matched] == state.text[pos+matched] do matched += 1
			best = max(best, matched)
		}
		finish := min(n, pos+best+1)
		state.starts[state.factor_count] = pos
		state.ends[state.factor_count] = finish
		state.factor_count += 1
		pos = finish
	}
	block := budget+2
	for first := 0; first < state.factor_count; first += block do
		divide(&state, first, min(state.factor_count, first+block)-1)

	records := 0
	for start := 0; start < n; start += 1 {
		for size := 2; size <= n-start; size += 1 {
			finish := start+size-1
			for period := 1; period <= size/2; period += 1 {
				index := (start*MAX_N+finish)*MAX_PERIODS+period
				if state.seen[index/64] & (u64(1) << u64(index%64)) != 0 do records += 1
			}
		}
	}
	written := 8+records*32
	if written > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(written) do return -2
	encode_i64(output, 0, u64(records))
	offset := 8
	for start := 0; start < n; start += 1 {
		for size := 2; size <= n-start; size += 1 {
			finish := start+size-1
			for period := 1; period <= size/2; period += 1 {
				index := (start*MAX_N+finish)*MAX_PERIODS+period
				if state.seen[index/64] & (u64(1) << u64(index%64)) == 0 do continue
				mismatches := 0
				for i := start; i <= finish-period; i += 1 do if state.text[i] != state.text[i+period] do mismatches += 1
				encode_i64(output, offset, u64(start)); offset += 8
				encode_i64(output, offset, u64(size)); offset += 8
				encode_i64(output, offset, u64(period)); offset += 8
				encode_i64(output, offset, u64(mismatches)); offset += 8
			}
		}
	}
	return i64(written)
}
