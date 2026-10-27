module procedure_s_general_cnf_sat

const max_vars = 5
const max_clauses = 6
const max_lits = max_vars * max_clauses

struct Formula { count int; lengths [6]int; literals [30]int }
struct Stats { calls i64; tests i64; branches i64; max_depth i64 }

fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}
fn shorten(f Formula, k int) Formula {
	mut d := Formula{count: f.count}
	for c in 0 .. f.count {
		d.lengths[c] = if f.lengths[c] < k { f.lengths[c] } else { k }
		for j in 0 .. d.lengths[c] { d.literals[c * max_vars + j] = f.literals[c * max_vars + j] }
	}
	return d
}
fn exact_sat(f Formula, n int, fixed_mask u32, fixed_values u32, mut model &u32) bool {
	limit := u32(1) << u32(n)
	for code in u32(0) .. limit {
		mut candidate := u32(0)
		for v in 0 .. n { if ((code >> u32(n - v - 1)) & 1) != 0 { candidate |= u32(1) << u32(v) } }
		if ((candidate ^ fixed_values) & fixed_mask) != 0 { continue }
		mut all := true
		for c in 0 .. f.count {
			mut one := false
			for j in 0 .. f.lengths[c] {
				lit := f.literals[c * max_vars + j]
				variable := if lit > 0 { lit - 1 } else { -lit - 1 }
				truth := ((candidate >> u32(variable)) & 1) != 0
				if (lit > 0 && truth) || (lit < 0 && !truth) { one = true; break }
			}
			if !one { all = false; break }
		}
		if all { model = candidate; return true }
	}
	return false
}
fn solve(f Formula, n int, k int, fixed_mask u32, fixed_values u32, depth int, mut stats &Stats, mut model &u32) bool {
	stats.calls++
	if i64(depth) > stats.max_depth { stats.max_depth = i64(depth) }
	d := shorten(f, k); stats.tests++
	if exact_sat(d, n, fixed_mask, fixed_values, mut model) { return true }
	for branch in 0 .. f.count {
		if d.lengths[branch] == 0 { continue }
		stats.branches++
		mut next_mask := fixed_mask; mut next_values := fixed_values; mut conflict := false
		for j in 0 .. d.lengths[branch] {
			lit := d.literals[branch * max_vars + j]
			variable := if lit > 0 { lit - 1 } else { -lit - 1 }
			bit := u32(1) << u32(variable); value := if lit < 0 { bit } else { u32(0) }
			if (next_mask & bit) != 0 && (next_values & bit) != value { conflict = true; break }
			next_mask |= bit; next_values = (next_values & ~bit) | value
		}
		if conflict || next_mask == fixed_mask { continue }
		mut child := Formula{}
		newly_fixed := next_mask & ~fixed_mask
		for c in 0 .. f.count {
			source := if c < branch { d } else { f }
			mut satisfied := false; mut kept := 0
			for j in 0 .. source.lengths[c] {
				lit := source.literals[c * max_vars + j]
				variable := if lit > 0 { lit - 1 } else { -lit - 1 }
				bit := u32(1) << u32(variable)
				if (newly_fixed & bit) != 0 {
					truth := (next_values & bit) != 0
					if (lit > 0 && truth) || (lit < 0 && !truth) { satisfied = true; break }
				} else { child.literals[child.count * max_vars + kept] = lit; kept++ }
			}
			if !satisfied { child.lengths[child.count] = kept; child.count++ }
		}
		if solve(child, n, k, next_mask, next_values, depth + 1, mut stats, mut model) { return true }
	}
	return false
}

@[export: 'procedure_s_general_cnf_sat']
pub fn procedure_s_general_cnf_sat(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > 39 { return -1 }
	unsafe {
		n0, m0, k0 := input[0], input[1], input[2]
		if n0 < 1 || n0 > max_vars || m0 < 0 || m0 > max_clauses || k0 < 1 || k0 > n0 { return -1 }
		n, m, k := int(n0), int(m0), int(k0)
		mut f := Formula{count: m}; mut at := 3
		for c in 0 .. m {
			if at >= int(length) || input[at] < 1 || input[at] > n0 { return -1 }
			count := int(input[at]); at++; if at + count > int(length) { return -1 }
			mut seen := u32(0); f.lengths[c] = count
			for j in 0 .. count {
				value := input[at]; at++
				if value == 0 || value > n0 || value < -n0 { return -1 }
				lit := int(value); variable := if lit > 0 { lit - 1 } else { -lit - 1 }
				bit := u32(1) << u32(variable); if (seen & bit) != 0 { return -1 }
				seen |= bit; f.literals[c * max_vars + j] = lit
			}
		}
		if at != int(length) { return -1 }
		mut stats := Stats{}; mut model := u32(0)
		sat := solve(f, n, k, 0, 0, 0, mut stats, mut model)
		if output == nil || capacity < 48 { return -2 }
		put_i64(mut output, 0, if sat { i64(1) } else { i64(0) })
		put_i64(mut output, 1, if sat { i64(model) } else { i64(0) })
		put_i64(mut output, 2, stats.calls); put_i64(mut output, 3, stats.tests)
		put_i64(mut output, 4, stats.branches); put_i64(mut output, 5, stats.max_depth)
		return 48
	}
}
