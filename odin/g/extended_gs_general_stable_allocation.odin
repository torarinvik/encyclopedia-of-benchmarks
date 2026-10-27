package extended_gs_general_stable_allocation

import "core:c"

MAX_INPUT :: 19
MAX_OUTPUT_BYTES :: 104
INF :: i64(255)

utility :: proc(first, second, count: i64) -> i64 {
	if count == 0 do return 0
	if count == 1 do return first
	return first + second
}

choose_men :: proc(men, women, edges: int, quota: i64, mf, ms, lower, upper: [4]i64) -> [4]i64 {
	answer: [4]i64
	best_value := i64(-1)
	codes := 1
	for e := 0; e < edges; e += 1 { codes *= 3 }
	for code := 0; code < codes; code += 1 {
		candidate: [4]i64
		rem := code
		for e := edges; e > 0; e -= 1 { index := e-1; candidate[index] = i64(rem % 3); rem /= 3 }
		feasible := true
		for e := 0; e < edges; e += 1 { if candidate[e] < lower[e] || candidate[e] > upper[e] do feasible = false }
		for i := 0; i < men; i += 1 {
			total := i64(0)
			for j := 0; j < women; j += 1 { total += candidate[i*women+j] }
			if total > quota do feasible = false
		}
		if !feasible do continue
		value := i64(0)
		for e := 0; e < edges; e += 1 { value += utility(mf[e],ms[e],candidate[e]) }
		if value > best_value { best_value = value; for e := 0; e < edges; e += 1 { answer[e] = candidate[e] } }
	}
	return answer
}

choose_women :: proc(men, women, edges: int, quota: i64, wf, ws, upper: [4]i64) -> [4]i64 {
	answer: [4]i64
	best_value := i64(-1)
	codes := 1
	for e := 0; e < edges; e += 1 { codes *= 3 }
	for code := 0; code < codes; code += 1 {
		candidate: [4]i64
		rem := code
		for e := edges; e > 0; e -= 1 { index := e-1; candidate[index] = i64(rem % 3); rem /= 3 }
		feasible := true
		for e := 0; e < edges; e += 1 { if candidate[e] > upper[e] do feasible = false }
		for j := 0; j < women; j += 1 {
			total := i64(0)
			for i := 0; i < men; i += 1 { total += candidate[i*women+j] }
			if total > quota do feasible = false
		}
		if !feasible do continue
		value := i64(0)
		for e := 0; e < edges; e += 1 { value += utility(wf[e],ws[e],candidate[e]) }
		if value > best_value { best_value = value; for e := 0; e < edges; e += 1 { answer[e] = candidate[e] } }
	}
	return answer
}

put_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> u64(8*byte)) & 255) }
}

@(export)
extended_gs_general_stable_allocation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > 2 || input[1] < 1 || input[1] > 2 || input[2] < 1 || input[2] > 2 do return -1
	men, women := int(input[0]), int(input[1])
	quota := input[2]
	edges := men * women
	if int(length) != 3 + 4*edges do return -1
	mf, ms, wf, ws: [4]i64
	for e := 0; e < edges; e += 1 {
		mf[e], ms[e] = input[3+4*e], input[4+4*e]
		wf[e], ws[e] = input[5+4*e], input[6+4*e]
		if mf[e] < 0 || mf[e] > 8 || ms[e] < 0 || ms[e] > mf[e] || wf[e] < 0 || wf[e] > 8 || ws[e] < 0 || ws[e] > wf[e] do return -1
	}
	x_w, z_w, x_m, next_w: [4]i64
	z_m: [4]i64
	for e := 0; e < edges; e += 1 { z_m[e] = INF }
	converged := false
	for iteration := 0; iteration < 3*edges+2; iteration += 1 {
		x_m = choose_men(men,women,edges,quota,mf,ms,x_w,z_m)
		next_w = choose_women(men,women,edges,quota,wf,ws,x_m)
		converged = true
		for e := 0; e < edges; e += 1 { if x_m[e] != next_w[e] do converged = false }
		if converged do break
		for e := 0; e < edges; e += 1 {
			if x_m[e] > next_w[e] { z_m[e] = next_w[e]; z_w[e] = INF }
			x_w[e] = next_w[e]
		}
	}
	if !converged do return -1
	output_values := 1 + 3*edges
	output_bytes := output_values*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	var staged: [MAX_OUTPUT_BYTES]u8
	put_i64(&staged[0],0,i64(edges))
	for e := 0; e < edges; e += 1 {
		put_i64(&staged[0],8*(1+e),x_m[e])
		put_i64(&staged[0],8*(1+edges+e),z_m[e])
		last := z_w[e]; if x_m[e] > last { last = x_m[e] }
		put_i64(&staged[0],8*(1+2*edges+e),last)
	}
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
