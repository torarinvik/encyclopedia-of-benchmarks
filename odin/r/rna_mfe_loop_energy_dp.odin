package rna_mfe_loop_energy_dp

import "core:c"

MAX_N :: 12
MAX_PAIRS :: 36
TABLE_VALUES :: 234
MAX_INPUT :: 247
MAX_OUTPUT :: 112
INF :: i64(1152921504606846976)

pair_type :: proc(a, b: i64) -> int {
	if a == 0 && b == 3 do return 0
	if a == 3 && b == 0 do return 1
	if a == 1 && b == 2 do return 2
	if a == 2 && b == 1 do return 3
	if a == 2 && b == 3 do return 4
	if a == 3 && b == 2 do return 5
	return -1
}

lex_less_mask :: proc(left, right: u64, count: int) -> bool {
	li, ri := 0, 0
	for {
		for li < count && ((left >> u64(li)) & 1) == 0 { li += 1 }
		for ri < count && ((right >> u64(ri)) & 1) == 0 { ri += 1 }
		if li == count || ri == count do return li == count && ri < count
		if li != ri do return li < ri
		li += 1; ri += 1
	}
}

loop_cost :: proc(input: [^]i64, n, kind, unpaired, children: int) -> i64 {
	return input[1+n+kind*39+unpaired*3+children]
}

put64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
rna_mfe_loop_energy_dp :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 239 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 4 || n64 > MAX_N || length != c.size_t(1+n64+TABLE_VALUES) do return -1
	n := int(n64)
	bases: [MAX_N]i64
	for i := 0; i < n; i += 1 { bases[i] = input[1+i]; if bases[i] < 0 || bases[i] > 3 do return -1 }
	for i := 1+n; i < int(length); i += 1 { if input[i] < -1000 || input[i] > 1000 do return -1 }
	types: [MAX_N][MAX_N]int
	ids: [MAX_N][MAX_N]int
	for i := 0; i < MAX_N; i += 1 { for j := 0; j < MAX_N; j += 1 { types[i][j] = -1; ids[i][j] = -1 } }
	pair_i: [MAX_PAIRS]int
	pair_j: [MAX_PAIRS]int
	pair_count := 0
	for i := 0; i < n; i += 1 { for j := i+4; j < n; j += 1 {
		kind := pair_type(bases[i], bases[j])
		if kind >= 0 { types[i][j]=kind; ids[i][j]=pair_count; pair_i[pair_count]=i; pair_j[pair_count]=j; pair_count += 1 }
	} }
	ve: [MAX_N][MAX_N]i64
	vm: [MAX_N][MAX_N]u64
	for i := 0; i < MAX_N; i += 1 { for j := 0; j < MAX_N; j += 1 { ve[i][j] = INF } }
	for span := 4; span < n; span += 1 { for i := 0; i+span < n; i += 1 {
		j := i+span; kind := types[i][j]; if kind < 0 do continue
		outer := u64(1) << u64(ids[i][j]); best := INF; best_mask: u64 = 0
		candidate := loop_cost(input,n,kind,span-1,0)
		if candidate < best || (candidate == best && lex_less_mask(outer,best_mask,pair_count)) { best=candidate; best_mask=outer }
		for a := i+1; a < j; a += 1 { for b := a+4; b < j; b += 1 {
			if ids[a][b] < 0 || ve[a][b] == INF do continue
			u := a-i-1+j-b-1; candidate=loop_cost(input,n,kind,u,1)+ve[a][b]; mask:=outer|vm[a][b]
			if candidate < best || (candidate == best && lex_less_mask(mask,best_mask,pair_count)) { best=candidate; best_mask=mask }
		} }
		for a := i+1; a < j; a += 1 { for b := a+4; b < j; b += 1 {
			if ids[a][b] < 0 || ve[a][b] == INF do continue
			for c0 := b+1; c0 < j; c0 += 1 { for d := c0+4; d < j; d += 1 {
				if ids[c0][d] < 0 || ve[c0][d] == INF do continue
				u := a-i-1+c0-b-1+j-d-1; candidate=loop_cost(input,n,kind,u,2)+ve[a][b]+ve[c0][d]; mask:=outer|vm[a][b]|vm[c0][d]
				if candidate < best || (candidate == best && lex_less_mask(mask,best_mask,pair_count)) { best=candidate; best_mask=mask }
			} }
		} }
		ve[i][j]=best; vm[i][j]=best_mask
	} }
	we: [MAX_N]i64
	wm: [MAX_N]u64
	for j := 0; j < n; j += 1 {
		best: i64 = 0; best_mask: u64 = 0
		if j > 0 { best=we[j-1]; best_mask=wm[j-1] }
		for i := 0; i+4 <= j; i += 1 {
			if types[i][j] < 0 || ve[i][j] == INF do continue
			prefix: i64 = 0; prefix_mask: u64 = 0
			if i > 0 { prefix=we[i-1]; prefix_mask=wm[i-1] }
			value := prefix+ve[i][j]; mask := prefix_mask|vm[i][j]
			if value < best || (value == best && lex_less_mask(mask,best_mask,pair_count)) { best=value; best_mask=mask }
		}
		we[j]=best; wm[j]=best_mask
	}
	count := 0
	for p := 0; p < pair_count; p += 1 { if ((wm[n-1] >> u64(p)) & 1) != 0 { count += 1 } }
	bytes := 8*(2+2*count)
	if output == nil || capacity < c.size_t(bytes) do return -2
	staged: [MAX_OUTPUT]u8
	put64(&staged[0],0,we[n-1]); put64(&staged[0],8,i64(count)); at := 2
	for p := 0; p < pair_count; p += 1 { if ((wm[n-1] >> u64(p)) & 1) != 0 { put64(&staged[0],8*at,i64(pair_i[p])); at += 1; put64(&staged[0],8*at,i64(pair_j[p])); at += 1 } }
	for byte := 0; byte < bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(bytes)
}
