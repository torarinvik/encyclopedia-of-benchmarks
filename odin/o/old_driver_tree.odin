package old_driver_tree

import "core:c"

MAX_N :: 32
MAX_Q :: 32
MAX_INPUT :: 195
MAX_RUNS :: 36

Run :: struct { left, right, value: i64 }
Operation :: struct { kind, left, right, arg, extra: i64 }

lower_bound :: proc "contextless" (runs: ^[MAX_RUNS]Run, count: int, point: i64) -> int {
	lo, hi := 0, count
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if runs^[mid].left < point { lo = mid + 1 } else { hi = mid }
	}
	return lo
}
split_at :: proc "contextless" (runs: ^[MAX_RUNS]Run, count: ^int, point, n: i64) {
	if point <= 0 || point >= n do return
	at := lower_bound(runs, count^, point)
	if at < count^ && runs^[at].left == point do return
	old := runs^[at - 1]
	i := count^
	for i > at { runs^[i] = runs^[i - 1]; i -= 1 }
	runs^[at - 1].right = point - 1
	runs^[at] = {point, old.right, old.value}
	count^ += 1
}
coalesce :: proc "contextless" (runs: ^[MAX_RUNS]Run, count: ^int) {
	write := 0
	for read := 0; read < count^; read += 1 {
		if write > 0 && runs^[write - 1].right + 1 == runs^[read].left && runs^[write - 1].value == runs^[read].value {
			runs^[write - 1].right = runs^[read].right
		} else { runs^[write] = runs^[read]; write += 1 }
	}
	count^ = write
}
modular_power :: proc "contextless" (base, exponent_input, modulus: i64) -> i64 {
	value := base % modulus
	if value < 0 { value += modulus }
	exponent := exponent_input
	result := i64(1) % modulus
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * value % modulus }
		value = value * value % modulus
		exponent >>= 1
	}
	return result
}
store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
old_driver_tree :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q || length < c.size_t(2 + nv) do return -1
	n, q := int(nv), int(qv)
	initial: [MAX_N]i64
	ops: [MAX_Q]Operation
	cursor, answer_count := 2 + n, 0
	for i := 0; i < n; i += 1 {
		initial[i] = input[2 + i]
		if initial[i] < -1000 || initial[i] > 1000 do return -1
	}
	for i := 0; i < q; i += 1 {
		if cursor >= int(length) do return -1
		kind := input[cursor]
		cursor += 1
		words := 0
		if kind == 3 { words = 4 } else if kind >= 0 && kind <= 2 { words = 3 }
		if words == 0 || int(length) - cursor < words do return -1
		op := Operation{kind, input[cursor], input[cursor + 1], input[cursor + 2], 0}
		cursor += 3
		if kind == 3 { op.extra = input[cursor]; cursor += 1 }
		if op.left < 0 || op.left > op.right || op.right >= nv do return -1
		if (kind <= 1 && (op.arg < -1000 || op.arg > 1000)) ||
		   (kind == 2 && (op.arg < 1 || op.arg > op.right - op.left + 1)) ||
		   (kind == 3 && (op.arg < 0 || op.arg > 8 || op.extra < 1 || op.extra > 1_000_000_000)) do return -1
		if kind >= 2 { answer_count += 1 }
		ops[i] = op
	}
	if cursor != int(length) || int(length) > 2 + MAX_N + 5 * MAX_Q do return -1
	required := 8 * answer_count
	if required > 0 && (output == nil || capacity < c.size_t(required)) do return -2
	runs: [MAX_RUNS]Run
	run_count := 0
	for i := 0; i < n; i += 1 {
		if run_count > 0 && runs[run_count - 1].value == initial[i] { runs[run_count - 1].right = i64(i) }
		else { runs[run_count] = {i64(i), i64(i), initial[i]}; run_count += 1 }
	}
	written := 0
	for oi := 0; oi < q; oi += 1 {
		op := ops[oi]
		if op.kind <= 1 {
			split_at(&runs, &run_count, op.right + 1, nv)
			split_at(&runs, &run_count, op.left, nv)
			start := lower_bound(&runs, run_count, op.left)
			finish := lower_bound(&runs, run_count, op.right + 1)
			if op.kind == 0 {
				removed, old_count := finish - start, run_count
				for i := finish; i < old_count; i += 1 { runs[i - removed] = runs[i] }
				run_count = old_count - removed
				for i := run_count; i > start; i -= 1 { runs[i] = runs[i - 1] }
				runs[start] = {op.left, op.right, op.arg}
				run_count += 1
			} else { for i := start; i < finish; i += 1 { runs[i].value += op.arg } }
			coalesce(&runs, &run_count)
		} else if op.kind == 2 {
			ordered: [MAX_N]i64
			used := 0
			for i := 0; i < run_count; i += 1 {
				lo, hi := max(runs[i].left, op.left), min(runs[i].right, op.right)
				for j := lo; j <= hi; j += 1 {
					at := used
					for at > 0 && ordered[at - 1] > runs[i].value { ordered[at] = ordered[at - 1]; at -= 1 }
					ordered[at] = runs[i].value
					used += 1
				}
			}
			store_le(output, 8 * written, ordered[int(op.arg - 1)])
			written += 1
		} else {
			total := i64(0)
			for i := 0; i < run_count; i += 1 {
				lo, hi := max(runs[i].left, op.left), min(runs[i].right, op.right)
				if lo <= hi { total = (total + (hi - lo + 1) * modular_power(runs[i].value, op.arg, op.extra)) % op.extra }
			}
			store_le(output, 8 * written, total)
			written += 1
		}
	}
	return i64(required)
}
