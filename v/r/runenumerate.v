module runenumerate

const max_n = 24
const max_runs = 144

struct Run {
	period int
	left int
	right int
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'runenumerate']
pub fn runenumerate(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_n + 1 { return -1 }
	n_value := input[0]
	if n_value < 1 || n_value > i64(max_n) || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut text := []int{len: max_n, init: 0}
	for i in 0 .. n {
		if input[i + 1] < 0 || input[i + 1] >= 26 { return -1 }
		text[i] = int(input[i + 1])
	}
	if output == nil { return -2 }

	stride := max_n + 1
	mut lcp := []int{len: stride * stride, init: 0}
	for i := n - 1; i >= 0; i-- {
		for j := n - 1; j > i; j-- {
			if text[i] == text[j] { lcp[i * stride + j] = 1 + lcp[(i + 1) * stride + j + 1] }
		}
	}
	mut runs := []Run{cap: max_runs}
	for period := 1; period <= n / 2; period++ {
		mut i := period
		for i < n {
			if text[i] != text[i - period] { i++; continue }
			first := i
			for i < n && text[i] == text[i - period] { i++ }
			left := first - period
			right := i
			if right - left < 2 * period { continue }
			mut minimal := true
			for smaller := 1; smaller < period; smaller++ {
				if lcp[left * stride + left + smaller] >= right - left - smaller {
					minimal = false
					break
				}
			}
			if minimal { runs << Run{period, left, right} }
		}
	}
	for i := 1; i < runs.len; i++ {
		value := runs[i]
		mut j := i
		for j > 0 && (runs[j - 1].period > value.period ||
			(runs[j - 1].period == value.period && runs[j - 1].left > value.left) ||
			(runs[j - 1].period == value.period && runs[j - 1].left == value.left && runs[j - 1].right > value.right)) {
			runs[j] = runs[j - 1]
			j--
		}
		runs[j] = value
	}
	needed := 8 + 24 * runs.len
	if capacity < usize(needed) { return -2 }
	store_i64_le(mut output, 0, i64(runs.len))
	for i, run in runs {
		offset := 8 + 24 * i
		store_i64_le(mut output, offset, i64(run.period))
		store_i64_le(mut output, offset + 8, i64(run.left))
		store_i64_le(mut output, offset + 16, i64(run.right))
	}
	return i64(needed)
}
