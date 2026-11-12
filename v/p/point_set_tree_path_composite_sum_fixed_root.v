module point_set_tree_path_composite_sum_fixed_root

const pts_mod = i64(998244353)
const pts_n = 16
const pts_q = 32
const pts_base = 16
const pts_input_max = 5 * pts_n + 4 * pts_q - 2

struct PtsAffine {
	m i64
	a i64
}

fn pts_compose(left PtsAffine, right PtsAffine) PtsAffine {
	return PtsAffine{m: left.m * right.m % pts_mod, a: (left.m * right.a + left.a) % pts_mod}
}
fn pts_find(mut parent [pts_n]int, x0 int) int {
	mut x := x0
	for parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
	return x
}
fn pts_set(mut seg [2 * pts_base]PtsAffine, pos [pts_n]int, mul [pts_n]i64, add [pts_n]i64, u int) {
	mut k := pts_base + pos[u]
	seg[k] = PtsAffine{m: mul[u], a: add[u]}; k /= 2
	for k > 0 { seg[k] = pts_compose(seg[2*k], seg[2*k+1]); k /= 2 }
}
fn pts_chain(seg [2 * pts_base]PtsAffine, pos [pts_n]int, ends [pts_n]int, h int) i64 {
	mut l := pts_base + pos[h]; mut r := pts_base + ends[h]
	mut left := PtsAffine{m: 1, a: 0}; mut right := left
	for l < r {
		if l & 1 == 1 { left = pts_compose(left, seg[l]); l++ }
		if r & 1 == 1 { r--; right = pts_compose(seg[r], right) }
		l /= 2; r /= 2
	}
	return pts_compose(left, right).a
}
fn pts_store(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'point_set_tree_path_composite_sum_fixed_root']
pub fn point_set_tree_path_composite_sum_fixed_root(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > pts_input_max { return -1 }
		nr, qr := input[0], input[1]
		if nr < 1 || nr > pts_n || qr < 1 || qr > pts_q { return -1 }
		n, q := int(nr), int(qr)
		mut cur := 2
		mut value := [pts_n]i64{}
		for u in 0 .. n { if cur >= int(length) { return -1 }; value[u] = input[cur]; cur++; if value[u] < 0 || value[u] >= pts_mod { return -1 } }
		mut edge_at := [pts_n][pts_n]int{}
		for u in 0 .. pts_n { for v in 0 .. pts_n { edge_at[u][v] = -1 } }
		mut eu, ev := [pts_n]int{}, [pts_n]int{}
		mut eb, ec := [pts_n]i64{}, [pts_n]i64{}
		mut dsu, dsz := [pts_n]int{}, [pts_n]int{}
		for u in 0 .. n { dsu[u] = u; dsz[u] = 1 }
		for e in 0 .. n-1 {
			if cur + 4 > int(length) { return -1 }
			ur, vr, b, c := input[cur], input[cur+1], input[cur+2], input[cur+3]; cur += 4
			if ur < 0 || ur >= nr || vr < 0 || vr >= nr || ur == vr || b < 1 || b >= pts_mod || c < 0 || c >= pts_mod { return -1 }
			u, v := int(ur), int(vr); mut ru := pts_find(mut dsu, u); mut rv := pts_find(mut dsu, v)
			if ru == rv { return -1 }; if dsz[ru] < dsz[rv] { ru, rv = rv, ru }
			dsu[rv] = ru; dsz[ru] += dsz[rv]; eu[e], ev[e], eb[e], ec[e] = u, v, b, c; edge_at[u][v], edge_at[v][u] = e, e
		}
		mut kind, ox, oy, oz := [pts_q]i64{}, [pts_q]i64{}, [pts_q]i64{}, [pts_q]i64{}
		for i in 0 .. q {
			if cur >= int(length) { return -1 }; kind[i] = input[cur]; cur++
			if kind[i] == 0 {
				if cur+2 > int(length) { return -1 }; ox[i], oy[i] = input[cur], input[cur+1]; cur += 2
				if ox[i] < 0 || ox[i] >= nr || oy[i] < 0 || oy[i] >= pts_mod { return -1 }
			} else if kind[i] == 1 {
				if cur+3 > int(length) { return -1 }; ox[i], oy[i], oz[i] = input[cur], input[cur+1], input[cur+2]; cur += 3
				if ox[i] < 0 || ox[i] >= nr-1 || oy[i] < 1 || oy[i] >= pts_mod || oz[i] < 0 || oz[i] >= pts_mod { return -1 }
			} else { return -1 }
		}
		}
		if cur != int(length) { return -1 }; bytes := 8*q
		if output == nil || capacity < usize(bytes) { return -2 }
		mut parent, pedge, order, stack := [pts_n]int{}, [pts_n]int{}, [pts_n]int{}, [pts_n]int{}
		mut sub, heavy := [pts_n]int{}, [pts_n]int{}
		for u in 0 .. n { parent[u], pedge[u], sub[u], heavy[u] = -2, -1, 1, -1 }
		parent[0] = -1; mut count, mut top := 0, 1; stack[0] = 0
		for top > 0 { top--; u := stack[top]; order[count] = u; count++; for v in 0 .. n { if edge_at[u][v] >= 0 && v != parent[u] { parent[v], pedge[v] = u, edge_at[u][v]; stack[top] = v; top++ } } }
		for ii in 0 .. count { u := order[count-1-ii]; mut best := 0; for v in 0 .. n { if parent[v] == u { sub[u] += sub[v]; if sub[v] > best || (sub[v] == best && (heavy[u] < 0 || v < heavy[u])) { best, heavy[u] = sub[v], v } } } }
		mut head, pos, ends, hs := [pts_n]int{}, [pts_n]int{}, [pts_n]int{}, [pts_n]int{}
		mut timer := 0; top = 1; hs[0] = 0
		for top > 0 { top--; h := hs[top]; mut u := h; for { head[u], pos[u] = h, timer; timer++; for v in 0 .. n { if parent[v] == u && v != heavy[u] { hs[top] = v; top++ } }; if heavy[u] < 0 { break }; u = heavy[u] }; ends[h] = timer }
		mut down := [pts_n]i64{}
		for ii in 0 .. count { u := order[count-1-ii]; down[u] = value[u]; for v in 0 .. n { if parent[v] == u { e := pedge[v]; down[u] += eb[e]*down[v] + ec[e]*i64(sub[v]) } }; down[u] %= pts_mod }
		mut lm, la := [pts_n]i64{}, [pts_n]i64{}
		for u in 0 .. n { la[u] = value[u]; for v in 0 .. n { if parent[v] == u { e := pedge[v]; if heavy[u] == v { lm[u] = eb[e]; la[u] += ec[e]*i64(sub[v]) } else { la[u] += eb[e]*down[v] + ec[e]*i64(sub[v]) } } }; la[u] %= pts_mod }
		mut seg := [2*pts_base]PtsAffine{}; for i in 0 .. 2*pts_base { seg[i] = PtsAffine{m: 1, a: 0} }; for u in 0 .. n { seg[pts_base+pos[u]] = PtsAffine{m: lm[u], a: la[u]} }; for ii in 0 .. pts_base-1 { i := pts_base-1-ii; seg[i] = pts_compose(seg[2*i],seg[2*i+1]) }
		mut current := [pts_n]i64{}; for u in 0 .. n { if head[u] == u { current[u] = down[u] } }
		for qi in 0 .. q { mut start := 0
			if kind[qi] == 0 { u := int(ox[qi]); la[u] = (la[u]+oy[qi]-value[u])%pts_mod; if la[u] < 0 { la[u] += pts_mod }; value[u] = oy[qi]; pts_set(mut seg,pos,lm,la,u); start = u }
			else { e := int(ox[qi]); u,v := eu[e],ev[e]; child := if parent[u] == v { u } else { v }; p := parent[child]; ob,oc := eb[e],ec[e]; if heavy[p] == child { lm[p] = oy[qi]; la[p] = (la[p]+(oz[qi]-oc)*i64(sub[child]))%pts_mod } else { la[p] = (la[p]+(oy[qi]-ob)*current[child]+(oz[qi]-oc)*i64(sub[child]))%pts_mod }; if la[p] < 0 { la[p] += pts_mod }; eb[e],ec[e] = oy[qi],oz[qi]; pts_set(mut seg,pos,lm,la,p); start = p }
			mut u := start; for { h := head[u]; old := current[h]; current[h] = pts_chain(seg,pos,ends,h); if h == 0 { break }; p,e := parent[h],pedge[h]; la[p] = (la[p]+eb[e]*(current[h]-old))%pts_mod; if la[p] < 0 { la[p] += pts_mod }; pts_set(mut seg,pos,lm,la,p); u = p }; pts_store(mut output,8*qi,current[0])
		}
		return i64(bytes)
	}
}
