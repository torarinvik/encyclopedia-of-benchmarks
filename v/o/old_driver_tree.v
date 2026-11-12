module old_driver_tree

const max_n = 32
const max_q = 32
const max_input = 195
const max_runs = 36

struct Run {
mut:
	left i64
	right i64
	value i64
}
struct Operation {
	kind i64
	left i64
	right i64
	arg i64
	extra i64
}

fn lower_bound(runs [max_runs]Run, count int, point i64) int {
	mut lo := 0
	mut hi := count
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if runs[mid].left < point { lo = mid + 1 } else { hi = mid }
	}
	return lo
}
fn split_at(mut runs [max_runs]Run, mut count int, point i64, n i64) {
	if point <= 0 || point >= n { return }
	at := lower_bound(runs, count, point)
	if at < count && runs[at].left == point { return }
	old := runs[at - 1]
	mut i := count
	for i > at { runs[i] = runs[i - 1]; i-- }
	runs[at - 1].right = point - 1
	runs[at] = Run{left: point, right: old.right, value: old.value}
	count++
}
fn coalesce(mut runs [max_runs]Run, mut count int) {
	mut write := 0
	for read in 0 .. count {
		if write > 0 && runs[write - 1].right + 1 == runs[read].left && runs[write - 1].value == runs[read].value {
			runs[write - 1].right = runs[read].right
		} else { runs[write] = runs[read]; write++ }
	}
	count = write
}
fn modular_power(base i64, exponent_input i64, modulus i64) i64 {
	mut value := base % modulus
	if value < 0 { value += modulus }
	mut exponent := exponent_input
	mut result := i64(1) % modulus
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * value % modulus }
		value = value * value % modulus
		exponent >>= 1
	}
	return result
}
fn store_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'old_driver_tree']
pub fn old_driver_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	unsafe {
		nv := input[0]
		qv := input[1]
		if nv < 1 || nv > max_n || qv < 0 || qv > max_q || length < usize(2 + nv) { return -1 }
		n := int(nv)
		q := int(qv)
		mut initial := [max_n]i64{}
		mut ops := [max_q]Operation{}
		mut cursor := 2 + n
		mut answer_count := 0
		for i in 0 .. n {
			initial[i] = input[2 + i]
			if initial[i] < -1000 || initial[i] > 1000 { return -1 }
		}
		for i in 0 .. q {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]
			cursor++
			words := if kind == 3 { 4 } else if kind >= 0 && kind <= 2 { 3 } else { 0 }
			if words == 0 || int(length) - cursor < words { return -1 }
			mut op := Operation{kind: kind, left: input[cursor], right: input[cursor + 1], arg: input[cursor + 2]}
			cursor += 3
			if kind == 3 { op.extra = input[cursor]; cursor++ }
			if op.left < 0 || op.left > op.right || op.right >= nv { return -1 }
			if (kind <= 1 && (op.arg < -1000 || op.arg > 1000)) ||
				(kind == 2 && (op.arg < 1 || op.arg > op.right - op.left + 1)) ||
				(kind == 3 && (op.arg < 0 || op.arg > 8 || op.extra < 1 || op.extra > 1_000_000_000)) { return -1 }
			if kind >= 2 { answer_count++ }
			ops[i] = op
		}
		if cursor != int(length) || int(length) > 2 + max_n + 5 * max_q { return -1 }
		required := 8 * answer_count
		if required > 0 && (unsafe { output == nil } || capacity < usize(required)) { return -2 }
		mut runs := [max_runs]Run{}
		mut run_count := 0
		for i in 0 .. n {
			if run_count > 0 && runs[run_count - 1].value == initial[i] { runs[run_count - 1].right = i64(i) }
			else { runs[run_count] = Run{left: i64(i), right: i64(i), value: initial[i]}; run_count++ }
		}
		mut written := 0
		for oi in 0 .. q {
			op := ops[oi]
			if op.kind <= 1 {
				split_at(mut runs, mut run_count, op.right + 1, nv)
				split_at(mut runs, mut run_count, op.left, nv)
				start := lower_bound(runs, run_count, op.left)
				finish := lower_bound(runs, run_count, op.right + 1)
				if op.kind == 0 {
					removed := finish - start
					old_count := run_count
					for i := finish; i < old_count; i++ { runs[i - removed] = runs[i] }
					run_count = old_count - removed
					mut i := run_count
					for i > start { runs[i] = runs[i - 1]; i-- }
					runs[start] = Run{left: op.left, right: op.right, value: op.arg}
					run_count++
				} else { for i := start; i < finish; i++ { runs[i].value += op.arg } }
				coalesce(mut runs, mut run_count)
			} else if op.kind == 2 {
				mut ordered := [max_n]i64{}
				mut used := 0
				for i in 0 .. run_count {
					lo := max(runs[i].left, op.left)
					hi := min(runs[i].right, op.right)
					if lo <= hi {
						for _ in 0 .. int(hi - lo + 1) {
							mut at := used
							for at > 0 && ordered[at - 1] > runs[i].value { ordered[at] = ordered[at - 1]; at-- }
							ordered[at] = runs[i].value
							used++
						}
					}
				}
				store_le(mut output, 8 * written, ordered[int(op.arg - 1)])
				written++
			} else {
				mut total := i64(0)
				for i in 0 .. run_count {
					lo := max(runs[i].left, op.left)
					hi := min(runs[i].right, op.right)
					if lo <= hi { total = (total + (hi - lo + 1) * modular_power(runs[i].value, op.arg, op.extra)) % op.extra }
				}
				store_le(mut output, 8 * written, total)
				written++
			}
		}
		return i64(required)
	}
}
