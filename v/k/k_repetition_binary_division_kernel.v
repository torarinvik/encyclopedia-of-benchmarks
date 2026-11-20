const max_n = 32
const max_k = 3
const max_input = 35
const max_periods = 17
const bit_words = 272
const max_factors = 33
const max_output = 91400

fn lp(text []int, lo int, hi int, center int, period int, allowed int) int {
	left := center - period
	limit := min(hi - left, hi - center)
	mut errors := 0
	for j in 0 .. limit {
		if text[left + j] != text[center + j] {
			errors++
			if errors > allowed { return j }
		}
	}
	return limit
}

fn ls(text []int, lo int, center int, period int, allowed int) int {
	limit := min(center - period - lo, center - lo)
	mut errors := 0
	for j in 0 .. limit {
		if text[center - period - 1 - j] != text[center - 1 - j] {
			errors++
			if errors > allowed { return j }
		}
	}
	return limit
}

fn mark(mut seen []u64, n int, lo int, last_head int, local_start int, local_end int, period int) {
	start, finish := lo + local_start, lo + local_end
	if start <= lo || finish >= n || finish - start + 1 < 2 * period { return }
	if start <= last_head + 1 && finish + 1 >= last_head { return }
	index := (start * max_n + finish) * max_periods + period
	seen[index / 64] |= u64(1) << u64(index % 64)
}

fn at_center(text []int, n int, budget int, lo int, center_global int, last_head int, mut seen []u64) {
	center := center_global - lo
	if center <= 0 || center + 1 >= text.len { return }
	for period in 1 .. center + 1 {
		for k in 0 .. budget + 1 {
			forward := lp(text, 0, text.len, center, period, k)
			backward := ls(text, 0, center, period, budget - k)
			if forward <= period && forward + backward >= period {
				mark(mut seen, n, lo, last_head, center - period - backward,
					center + forward - 1, period)
			}
		}
	}
	mut reversed := []int{len: text.len}
	for i in 0 .. text.len { reversed[i] = text[text.len - 1 - i] }
	rc := text.len - 1 - center
	for period in 1 .. rc + 1 {
		for k in 0 .. budget + 1 {
			forward := lp(reversed, 0, text.len, rc, period, k)
			backward := ls(reversed, 0, rc, period, budget - k)
			if forward <= period && forward + backward >= period {
				rs, re := rc - period - backward, rc + forward - 1
				mark(mut seen, n, lo, last_head, text.len - 1 - re,
					text.len - 1 - rs, period)
			}
		}
	}
}

fn divide(text []int, n int, starts []int, ends []int, budget int, mut seen []u64, first int, last int) {
	if first >= last { return }
	middle := first + (last - first) / 2
	lo, hi := starts[first], ends[last]
	center, last_head := ends[middle] - 1, ends[last] - 1
	at_center(text[lo..hi], n, budget, lo, center, last_head, mut seen)
	divide(text, n, starts, ends, budget, mut seen, first, middle)
	divide(text, n, starts, ends, budget, mut seen, middle + 1, last)
}

fn encode_i64(mut output &u8, offset int, value u64) {
	unsafe {
		for byte in 0 .. 8 { output[offset + byte] = u8((value >> u64(8 * byte)) & 255) }
	}
}

@[export: 'k_repetition_binary_division_kernel']
pub fn k_repetition_binary_division_kernel(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		nv, kv := input[0], input[1]
		if nv < 1 || nv > max_n || kv < 0 || kv > max_k { return -1 }
		n, budget := int(nv), int(kv)
		if length != usize(n + 2) { return -1 }
		mut text := []int{len: max_n}
		for i in 0 .. n {
			if input[i + 2] < 0 || input[i + 2] > 4 { return -1 }
			text[i] = int(input[i + 2])
		}
		for i in 0 .. n - 1 { if text[i] == text[n - 1] { return -1 } }

		mut starts := []int{len: max_factors}
		mut ends := []int{len: max_factors}
		mut factor_count := 0
		mut pos := 0
		for pos < n {
			mut best := 0
			for earlier in 0 .. pos {
				mut matched := 0
				for pos + matched < n && earlier + matched < n && text[earlier + matched] == text[pos + matched] { matched++ }
				best = max(best, matched)
			}
			finish := min(n, pos + best + 1)
			starts[factor_count] = pos
			ends[factor_count] = finish
			factor_count++
			pos = finish
		}
		mut seen := []u64{len: bit_words}
		block := budget + 2
		for first := 0; first < factor_count; first += block {
			divide(text, n, starts, ends, budget, mut seen, first, min(factor_count, first + block) - 1)
		}
		mut records := 0
		for start in 0 .. n {
			for size in 2 .. n - start + 1 {
				finish := start + size - 1
				for period in 1 .. size / 2 + 1 {
					index := (start * max_n + finish) * max_periods + period
					if seen[index / 64] & (u64(1) << u64(index % 64)) != 0 { records++ }
				}
			}
		}
		written := 8 + records * 32
		if written > max_output { return -1 }
		if output == nil || capacity < usize(written) { return -2 }
		encode_i64(mut output, 0, u64(records))
		mut offset := 8
		for start in 0 .. n {
			for size in 2 .. n - start + 1 {
				finish := start + size - 1
				for period in 1 .. size / 2 + 1 {
					index := (start * max_n + finish) * max_periods + period
					if seen[index / 64] & (u64(1) << u64(index % 64)) == 0 { continue }
					mut mismatches := 0
					for i := start; i <= finish - period; i++ { if text[i] != text[i + period] { mismatches++ } }
					encode_i64(mut output, offset, u64(start)); offset += 8
					encode_i64(mut output, offset, u64(size)); offset += 8
					encode_i64(mut output, offset, u64(period)); offset += 8
					encode_i64(mut output, offset, u64(mismatches)); offset += 8
				}
			}
		}
		return i64(written)
	}
}
