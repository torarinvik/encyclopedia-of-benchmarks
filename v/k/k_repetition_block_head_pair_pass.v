module k_repetition_block_head_pair_pass

const max_n = 24
const max_k = 3
const max_input = 27
const max_context = 48
const max_factors = 25
const max_periods = 13
const bit_words = 117
const max_output = 39112

struct Pass {
mut:
	text [max_n]int
	starts [max_factors]int
	ends [max_factors]int
	seen [bit_words]u64
	n int
	budget int
	factor_count int
}

fn right_extend(w []int, center int, period int, allowed int) int {
	left := center - period
	limit := min(w.len - left, w.len - center)
	mut errors := 0
	for d in 0 .. limit {
		if w[left + d] != w[center + d] {
			errors++
			if errors > allowed { return d }
		}
	}
	return limit
}

fn left_extend(w []int, center int, period int, allowed int) int {
	limit := center - period
	mut errors := 0
	for d in 0 .. limit {
		if w[center - period - 1 - d] != w[center - 1 - d] {
			errors++
			if errors > allowed { return d }
		}
	}
	return limit
}

fn mark(mut s Pass, base int, size int, center int, next int, lo int, hi int, period int) {
	if hi >= size || hi - lo + 1 < 2 * period { return }
	if lo > center + 1 || hi + 1 < center { return }
	if lo <= next + 1 && hi + 1 >= next { return }
	start, finish := base + lo, base + hi
	if finish >= s.n { return }
	index := (start * max_n + finish) * max_periods + period
	s.seen[index / 64] |= u64(1) << u64(index % 64)
}

fn at_head(mut s Pass, w []int, base int, center int, next int) {
	if center <= 0 || center + 1 >= w.len { return }
	for period in 1 .. center + 1 {
		for split in 0 .. s.budget + 1 {
			f := right_extend(w, center, period, split)
			b := left_extend(w, center, period, s.budget - split)
			if f <= period && f + b >= period {
				mark(mut s, base, w.len, center, next, center - period - b, center + f - 1, period)
			}
		}
	}
	mut reversed := []int{len: w.len}
	for i in 0 .. w.len { reversed[i] = w[w.len - 1 - i] }
	rc := w.len - 1 - center
	for period in 1 .. rc + 1 {
		for split in 0 .. s.budget + 1 {
			f := right_extend(reversed, rc, period, split)
			b := left_extend(reversed, rc, period, s.budget - split)
			if f <= period && f + b >= period {
				rs, re := rc - period - b, rc + f - 1
				mark(mut s, base, w.len, center, next, w.len - 1 - re, w.len - 1 - rs, period)
			}
		}
	}
}

fn factorize(mut s Pass) {
	mut pos := 0
	for pos < s.n {
		mut best := 0
		for earlier in 0 .. pos {
			mut matched := 0
			for pos + matched < s.n && earlier + matched < s.n && s.text[earlier + matched] == s.text[pos + matched] { matched++ }
			best = max(best, matched)
		}
		finish := min(s.n, pos + best + 1)
		s.starts[s.factor_count] = pos
		s.ends[s.factor_count] = finish
		s.factor_count++
		pos = finish
	}
}

fn run_heads(mut s Pass) {
	block := s.budget + 2
	blocks := (s.factor_count + block - 1) / block
	for bi in 0 .. max(0, blocks - 1) {
		first := bi * block
		first_end := min(s.factor_count, first + block)
		second_end := min(s.factor_count, first_end + block)
		head, next := s.ends[first_end - 1] - 1, s.ends[second_end - 1] - 1
		pair_start, pair_end := s.starts[first], s.ends[second_end - 1]
		span := pair_end - pair_start
		base := max(0, pair_start - span)
		size := pair_end - base
		mut local := []int{len: size}
		for i in 0 .. size { local[i] = s.text[base + i] }
		at_head(mut s, local, base, head - base, next - base)
	}
}

fn marked(s &Pass, start int, finish int, period int) bool {
	index := (start * max_n + finish) * max_periods + period
	return s.seen[index / 64] & (u64(1) << u64(index % 64)) != 0
}

fn put_i64(mut output &u8, offset int, value u64) {
	unsafe {
		for b in 0 .. 8 { output[offset + b] = u8((value >> u64(8 * b)) & 255) }
	}
}

@[export: 'k_repetition_block_head_pair_pass']
pub fn k_repetition_block_head_pair_pass(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		nv, kv := input[0], input[1]
		if nv < 1 || nv > max_n || kv < 0 || kv > max_k { return -1 }
		n, budget := int(nv), int(kv)
		if length != usize(n + 2) { return -1 }
		mut state := Pass{n: n, budget: budget}
		for i in 0 .. n {
			if input[i + 2] < 0 || input[i + 2] > 4 { return -1 }
			state.text[i] = int(input[i + 2])
		}
		for i in 0 .. n - 1 { if state.text[i] == state.text[n - 1] { return -1 } }
		factorize(mut state)
		run_heads(mut state)
		mut count := 0
		for start in 0 .. n {
			for size in 2 .. n - start + 1 {
				finish := start + size - 1
				for period in 1 .. size / 2 + 1 { if marked(state, start, finish, period) { count++ } }
			}
		}
		written := 8 + count * 32
		if written > max_output { return -1 }
		if output == nil || capacity < usize(written) { return -2 }
		put_i64(mut output, 0, u64(count))
		mut offset := 8
		for start in 0 .. n {
			for size in 2 .. n - start + 1 {
				finish := start + size - 1
				for period in 1 .. size / 2 + 1 {
					if !marked(state, start, finish, period) { continue }
					mut errors := 0
					for i := start; i <= finish - period; i++ { if state.text[i] != state.text[i + period] { errors++ } }
					put_i64(mut output, offset, u64(start)); offset += 8
					put_i64(mut output, offset, u64(size)); offset += 8
					put_i64(mut output, offset, u64(period)); offset += 8
					put_i64(mut output, offset, u64(errors)); offset += 8
				}
			}
		}
		return i64(written)
	}
}
