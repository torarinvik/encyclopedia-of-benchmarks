package procedure_s_general_cnf_sat

import "core:c"

Max_Vars :: 5
Max_Clauses :: 6
Max_Lits :: Max_Vars * Max_Clauses
Formula :: struct { count: int, lengths: [Max_Clauses]int, literals: [Max_Lits]int }
Stats :: struct { calls, tests, branches, max_depth: i64 }

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

shorten :: proc "contextless" (f: Formula, k: int) -> Formula {
	d := Formula{count = f.count}
	for c := 0; c < f.count; c += 1 {
		d.lengths[c] = min(f.lengths[c], k)
		for j := 0; j < d.lengths[c]; j += 1 { d.literals[c*Max_Vars+j] = f.literals[c*Max_Vars+j] }
	}
	return d
}

exact_sat :: proc "contextless" (f: Formula, n: int, fixed_mask, fixed_values: u32, model: ^u32) -> bool {
	limit := u32(1) << u32(n)
	for code := u32(0); code < limit; code += 1 {
		candidate: u32 = 0
		for v := 0; v < n; v += 1 { if ((code >> u32(n-v-1)) & 1) != 0 { candidate |= u32(1) << u32(v) } }
		if ((candidate ^ fixed_values) & fixed_mask) != 0 do continue
		all := true
		for c := 0; c < f.count && all; c += 1 {
			one := false
			for j := 0; j < f.lengths[c]; j += 1 {
				lit := f.literals[c*Max_Vars+j]
				variable := lit-1; if lit < 0 { variable = -lit-1 }
				truth := ((candidate >> u32(variable)) & 1) != 0
				if (lit > 0 && truth) || (lit < 0 && !truth) { one = true; break }
			}
			all = one
		}
		if all { model^ = candidate; return true }
	}
	return false
}

solve :: proc "contextless" (f: Formula, n, k: int, fixed_mask, fixed_values: u32,
	depth: int, stats: ^Stats, model: ^u32) -> bool {
	stats.calls += 1
	if i64(depth) > stats.max_depth { stats.max_depth = i64(depth) }
	d := shorten(f, k); stats.tests += 1
	if exact_sat(d, n, fixed_mask, fixed_values, model) do return true
	for branch := 0; branch < f.count; branch += 1 {
		if d.lengths[branch] == 0 do continue
		stats.branches += 1
		next_mask, next_values := fixed_mask, fixed_values
		conflict := false
		for j := 0; j < d.lengths[branch]; j += 1 {
			lit := d.literals[branch*Max_Vars+j]
			variable := lit-1; if lit < 0 { variable = -lit-1 }
			bit := u32(1) << u32(variable)
			value: u32 = 0; if lit < 0 { value = bit }
			if (next_mask & bit) != 0 && (next_values & bit) != value { conflict = true; break }
			next_mask |= bit; next_values = (next_values & ~bit) | value
		}
		if conflict || next_mask == fixed_mask do continue
		child := Formula{}
		newly_fixed := next_mask & ~fixed_mask
		for c := 0; c < f.count; c += 1 {
			source := f; if c < branch { source = d }
			satisfied := false; kept := 0
			for j := 0; j < source.lengths[c]; j += 1 {
				lit := source.literals[c*Max_Vars+j]
				variable := lit-1; if lit < 0 { variable = -lit-1 }
				bit := u32(1) << u32(variable)
				if (newly_fixed & bit) != 0 {
					truth := (next_values & bit) != 0
					if (lit > 0 && truth) || (lit < 0 && !truth) { satisfied = true; break }
				} else { child.literals[child.count*Max_Vars+kept] = lit; kept += 1 }
			}
			if !satisfied { child.lengths[child.count] = kept; child.count += 1 }
		}
		if solve(child, n, k, next_mask, next_values, depth+1, stats, model) do return true
	}
	return false
}

procedure_s_general_cnf_sat :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
	output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 39 do return -1
	n0, m0, k0 := input[0], input[1], input[2]
	if n0 < 1 || n0 > Max_Vars || m0 < 0 || m0 > Max_Clauses || k0 < 1 || k0 > n0 do return -1
	n, m, k := int(n0), int(m0), int(k0)
	f := Formula{count = m}; at := 3
	for c := 0; c < m; c += 1 {
		if at >= int(length) || input[at] < 1 || input[at] > n0 do return -1
		count := int(input[at]); at += 1; if at+count > int(length) do return -1
		seen: u32 = 0; f.lengths[c] = count
		for j := 0; j < count; j += 1 {
			value := input[at]; at += 1
			if value == 0 || value > n0 || value < -n0 do return -1
			lit := int(value); variable := lit-1; if lit < 0 { variable = -lit-1 }
			bit := u32(1) << u32(variable); if (seen & bit) != 0 do return -1
			seen |= bit; f.literals[c*Max_Vars+j] = lit
		}
	}
	if at != int(length) do return -1
	stats := Stats{}; model: u32 = 0
	sat := solve(f, n, k, 0, 0, 0, &stats, &model)
	if output == nil || output_capacity < 48 do return -2
	put_i64(output, 0, if sat {1} else {0}); put_i64(output, 1, if sat {i64(model)} else {0})
	put_i64(output, 2, stats.calls); put_i64(output, 3, stats.tests)
	put_i64(output, 4, stats.branches); put_i64(output, 5, stats.max_depth)
	return 48
}
