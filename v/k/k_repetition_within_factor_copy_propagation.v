module k_repetition_within_factor_copy_propagation

const max_n = 16
const max_k = 3
const max_input = 1557
const max_records = 372
const periods = 9
const bit_words = 39
const max_output = 11912

struct Record {
mut:
	start int
	finish int
	period int
	errors int
}

struct State {
mut:
	word [max_n]int
	starts [max_n]int
	ends [max_n]int
	copies [max_n]int
	records [max_records]Record
	known [bit_words]u64
	generated [bit_words]u64
	n int
	budget int
	factor_count int
	record_count int
}

fn bit_index(start int, finish int, period int) int {
	return (start * (max_n + 1) + finish) * periods + period
}

fn marked(bits []u64, bit int) bool {
	return (bits[bit / 64] & (u64(1) << u64(bit % 64))) != 0
}

fn lce(s &State, left int, right int) int {
	mut length := 0
	for left + length < s.n && right + length < s.n && s.word[left + length] == s.word[right + length] {
		length++
	}
	return length
}

fn less_record(a Record, b Record) bool {
	if a.start != b.start { return a.start < b.start }
	if a.finish != b.finish { return a.finish < b.finish }
	if a.period != b.period { return a.period < b.period }
	return a.errors < b.errors
}

fn add_record(mut s State, record Record, is_generated bool) {
	bit := bit_index(record.start, record.finish, record.period)
	if marked(s.known[..], bit) { return }
	s.known[bit / 64] |= u64(1) << u64(bit % 64)
	if is_generated { s.generated[bit / 64] |= u64(1) << u64(bit % 64) }
	mut at := s.record_count
	for at > 0 && less_record(record, s.records[at - 1]) {
		s.records[at] = s.records[at - 1]
		at--
	}
	s.records[at] = record
	s.record_count++
}

fn factors_valid(s &State) bool {
	if s.factor_count <= 0 || s.factor_count > s.n { return false }
	mut position := 0
	for f in 0 .. s.factor_count {
		a, b, c := s.starts[f], s.ends[f], s.copies[f]
		if a != position || a < 0 || b <= a || b > s.n { return false }
		if f == 0 {
			if a != 0 || b != 1 || c != -1 { return false }
			position = b
			continue
		}
		mut longest := 0
		for earlier in 0 .. a { longest = max(longest, lce(s, earlier, a)) }
		if b != min(s.n, a + longest + 1) { return false }
		prefix := b - a - 1
		if prefix == 0 {
			if c != -1 { return false }
		} else if c < 0 || c >= a || lce(s, c, a) != prefix {
			return false
		}
		position = b
	}
	return position == s.n
}

fn mismatch_count(s &State, start int, finish int, period int) int {
	mut errors := 0
	for i := start; i < finish - period; i++ { if s.word[i] != s.word[i + period] { errors++ } }
	return errors
}

fn seed_valid(s &State, r Record) bool {
	a, b, p := r.start, r.finish, r.period
	if a < 0 || a >= b || b > s.n || p < 1 || p > s.n / 2 || b - a < 2 * p { return false }
	errors := mismatch_count(s, a, b, p)
	if errors != r.errors || errors > s.budget { return false }
	if a > 0 && errors + int(s.word[a - 1] != s.word[a + p - 1]) <= s.budget { return false }
	if b < s.n && errors + int(s.word[b - p] != s.word[b]) <= s.budget { return false }
	return true
}

fn propagate(mut s State) {
	for f in 0 .. s.factor_count {
		a, b, c := s.starts[f], s.ends[f], s.copies[f]
		copied := b - a - 1
		if copied <= 0 { continue }
		delta, copy_end := a - c, c + copied
		for target := a + 1; target < b - 1; target++ {
			source_start := target - delta
			mut index := 0
			for index < s.record_count && s.records[index].start < source_start { index++ }
			for index < s.record_count && s.records[index].start == source_start {
				source := s.records[index]
				if source.finish > copy_end { break }
				target_end := source.finish + delta
				if target_end <= b - 2 {
					add_record(mut s, Record{start: target, finish: target_end, period: source.period, errors: source.errors}, true)
				}
				index++
			}
		}
	}
}

fn put_i64(mut output &u8, offset int, value u64) {
	unsafe { for b in 0 .. 8 { output[offset + b] = u8((value >> u64(8 * b)) & 255) } }
}

@[export: 'k_repetition_within_factor_copy_propagation']
pub fn k_repetition_within_factor_copy_propagation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		nv, kv := input[0], input[1]
		if nv < 1 || nv > max_n || kv < 0 || kv > max_k { return -1 }
		n, budget := int(nv), int(kv)
		if length < usize(n + 3) { return -1 }
		mut s := State{n: n, budget: budget}
		mut cursor := 2
		for i in 0 .. n {
			if input[cursor] < 0 || input[cursor] > 5 { return -1 }
			s.word[i] = int(input[cursor]); cursor++
		}
		for i in 0 .. n - 1 { if s.word[i] == s.word[n - 1] { return -1 } }
		if cursor >= int(length) || input[cursor] < 1 || input[cursor] > i64(n) { return -1 }
		s.factor_count = int(input[cursor]); cursor++
		if cursor + 3 * s.factor_count >= int(length) { return -1 }
		for i in 0 .. s.factor_count {
			a, b, c := input[cursor], input[cursor + 1], input[cursor + 2]
			if a < 0 || a > i64(n) || b < 0 || b > i64(n) || c < -1 || c > i64(n) { return -1 }
			s.starts[i], s.ends[i], s.copies[i] = int(a), int(b), int(c)
			cursor += 3
		}
		if cursor >= int(length) || !factors_valid(s) { return -1 }
		seed_count := input[cursor]; cursor++
		if seed_count < 0 || seed_count > max_records || cursor + 4 * int(seed_count) != int(length) { return -1 }
		for _ in 0 .. int(seed_count) {
			a, b, p, e := input[cursor], input[cursor + 1], input[cursor + 2], input[cursor + 3]
			if a < 0 || a > i64(n) || b < 0 || b > i64(n) || p < 0 || p > i64(n) || e < 0 || e > max_k { return -1 }
			r := Record{start: int(a), finish: int(b), period: int(p), errors: int(e)}
			if !seed_valid(s, r) { return -1 }
			add_record(mut s, r, false)
			cursor += 4
		}
		propagate(mut s)
		mut count := 0
		for i in 0 .. s.record_count {
			r := s.records[i]
			if marked(s.generated[..], bit_index(r.start, r.finish, r.period)) { count++ }
		}
		written := 8 + count * 32
		if written > max_output { return -1 }
		if output == nil || capacity < usize(written) { return -2 }
		put_i64(mut output, 0, u64(count))
		mut offset := 8
		for i in 0 .. s.record_count {
			r := s.records[i]
			if !marked(s.generated[..], bit_index(r.start, r.finish, r.period)) { continue }
			put_i64(mut output, offset, u64(r.start)); offset += 8
			put_i64(mut output, offset, u64(r.finish)); offset += 8
			put_i64(mut output, offset, u64(r.period)); offset += 8
			put_i64(mut output, offset, u64(r.errors)); offset += 8
		}
		return i64(written)
	}
}
