package k_repetition_within_factor_copy_propagation

import "core:c"

MAX_N :: 16
MAX_K :: 3
MAX_INPUT :: 1557
MAX_RECORDS :: 372
PERIODS :: 9
BIT_WORDS :: 39
MAX_OUTPUT :: 11912

Record :: struct { start, finish, period, errors: int }
State :: struct {
	word: [MAX_N]int,
	starts, ends, copies: [MAX_N]int,
	records: [MAX_RECORDS]Record,
	known, generated: [BIT_WORDS]u64,
	n, budget, factor_count, record_count: int,
}

bit_index :: proc(start, finish, period: int) -> int {
	return (start*(MAX_N+1)+finish)*PERIODS+period
}

marked :: proc(bits: [^]u64, bit: int) -> bool {
	return bits[bit/64] & (u64(1) << u64(bit%64)) != 0
}

lce :: proc(s: ^State, left, right: int) -> int {
	length := 0
	for left+length < s.n && right+length < s.n && s.word[left+length] == s.word[right+length] {
		length += 1
	}
	return length
}

less_record :: proc(a, b: Record) -> bool {
	if a.start != b.start do return a.start < b.start
	if a.finish != b.finish do return a.finish < b.finish
	if a.period != b.period do return a.period < b.period
	return a.errors < b.errors
}

add_record :: proc(s: ^State, record: Record, is_generated: bool) {
	bit := bit_index(record.start, record.finish, record.period)
	if marked(&s.known[0], bit) do return
	s.known[bit/64] |= u64(1) << u64(bit%64)
	if is_generated do s.generated[bit/64] |= u64(1) << u64(bit%64)
	at := s.record_count
	for at > 0 && less_record(record, s.records[at-1]) {
		s.records[at] = s.records[at-1]
		at -= 1
	}
	s.records[at] = record
	s.record_count += 1
}

factors_valid :: proc(s: ^State) -> bool {
	if s.factor_count <= 0 || s.factor_count > s.n do return false
	position := 0
	for f := 0; f < s.factor_count; f += 1 {
		a, b, c := s.starts[f], s.ends[f], s.copies[f]
		if a != position || a < 0 || b <= a || b > s.n do return false
		if f == 0 {
			if a != 0 || b != 1 || c != -1 do return false
			position = b
			continue
		}
		longest := 0
		for earlier := 0; earlier < a; earlier += 1 { longest = max(longest, lce(s, earlier, a)) }
		if b != min(s.n, a+longest+1) do return false
		prefix := b-a-1
		if prefix == 0 {
			if c != -1 do return false
		} else if c < 0 || c >= a || lce(s, c, a) != prefix {
			return false
		}
		position = b
	}
	return position == s.n
}

mismatch_count :: proc(s: ^State, start, finish, period: int) -> int {
	errors := 0
	for i := start; i < finish-period; i += 1 { if s.word[i] != s.word[i+period] do errors += 1 }
	return errors
}

seed_valid :: proc(s: ^State, r: Record) -> bool {
	a, b, p := r.start, r.finish, r.period
	if a < 0 || a >= b || b > s.n || p < 1 || p > s.n/2 || b-a < 2*p do return false
	errors := mismatch_count(s, a, b, p)
	if errors != r.errors || errors > s.budget do return false
	if a > 0 && errors+int(s.word[a-1] != s.word[a+p-1]) <= s.budget do return false
	if b < s.n && errors+int(s.word[b-p] != s.word[b]) <= s.budget do return false
	return true
}

propagate :: proc(s: ^State) {
	for f := 0; f < s.factor_count; f += 1 {
		a, b, c := s.starts[f], s.ends[f], s.copies[f]
		copied := b-a-1
		if copied <= 0 do continue
		delta, copy_end := a-c, c+copied
		for target := a+1; target < b-1; target += 1 {
			source_start := target-delta
			index := 0
			for index < s.record_count && s.records[index].start < source_start { index += 1 }
			for index < s.record_count && s.records[index].start == source_start {
				source := s.records[index]
				if source.finish > copy_end do break
				target_end := source.finish+delta
				if target_end <= b-2 {
					add_record(s, {target, target_end, source.period, source.errors}, true)
				}
				index += 1
			}
		}
	}
}

put_i64 :: proc(output: [^]u8, offset: int, value: u64) {
	for b := 0; b < 8; b += 1 { output[offset+b] = u8((value >> u64(8*b)) & 255) }
}

@(export)
k_repetition_within_factor_copy_propagation :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT) do return -1
	nv, kv := input[0], input[1]
	if nv < 1 || nv > MAX_N || kv < 0 || kv > MAX_K do return -1
	n, budget := int(nv), int(kv)
	if length < c.size_t(n+3) do return -1
	s: State = {}
	s.n, s.budget = n, budget
	cursor := 2
	for i := 0; i < n; i += 1 {
		if input[cursor] < 0 || input[cursor] > 5 do return -1
		s.word[i] = int(input[cursor]); cursor += 1
	}
	for i := 0; i+1 < n; i += 1 do if s.word[i] == s.word[n-1] do return -1
	if cursor >= int(length) || input[cursor] < 1 || input[cursor] > i64(n) do return -1
	s.factor_count = int(input[cursor]); cursor += 1
	if cursor+3*s.factor_count >= int(length) do return -1
	for i := 0; i < s.factor_count; i += 1 {
		a, b, c := input[cursor], input[cursor+1], input[cursor+2]
		if a < 0 || a > i64(n) || b < 0 || b > i64(n) || c < -1 || c > i64(n) do return -1
		s.starts[i], s.ends[i], s.copies[i] = int(a), int(b), int(c)
		cursor += 3
	}
	if cursor >= int(length) || !factors_valid(&s) do return -1
	seed_count := input[cursor]; cursor += 1
	if seed_count < 0 || seed_count > MAX_RECORDS || cursor+4*int(seed_count) != int(length) do return -1
	for i := 0; i < int(seed_count); i += 1 {
		a, b, p, e := input[cursor], input[cursor+1], input[cursor+2], input[cursor+3]
		if a < 0 || a > i64(n) || b < 0 || b > i64(n) || p < 0 || p > i64(n) || e < 0 || e > MAX_K do return -1
		r := Record{int(a), int(b), int(p), int(e)}
		if !seed_valid(&s, r) do return -1
		add_record(&s, r, false)
		cursor += 4
	}
	propagate(&s)
	count := 0
	for i := 0; i < s.record_count; i += 1 {
		r := s.records[i]
		if marked(&s.generated[0], bit_index(r.start, r.finish, r.period)) do count += 1
	}
	written := 8+count*32
	if written > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(written) do return -2
	put_i64(output, 0, u64(count))
	offset := 8
	for i := 0; i < s.record_count; i += 1 {
		r := s.records[i]
		if !marked(&s.generated[0], bit_index(r.start, r.finish, r.period)) do continue
		put_i64(output, offset, u64(r.start)); offset += 8
		put_i64(output, offset, u64(r.finish)); offset += 8
		put_i64(output, offset, u64(r.period)); offset += 8
		put_i64(output, offset, u64(r.errors)); offset += 8
	}
	return i64(written)
}
