package point_set_tree_path_composite_sum_fixed_root

import "core:c"

N :: 16
Q :: 32
BASE :: 16
INPUT_MAX :: 5*N + 4*Q - 2
MOD :: i64(998244353)

pts_find :: proc "contextless" (parent: [^]int, x0: int) -> int {
	x := x0
	for parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
	return x
}
pts_compose :: proc "contextless" (lm, la, rm, ra: i64, out: [^]i64) {
	out[0] = lm*rm % MOD
	out[1] = (lm*ra + la) % MOD
}
pts_set :: proc "contextless" (u: int, pos: [^]int, lm, la: [^]i64, sm, sa: [^]i64) {
	k := BASE + pos[u]; sm[k] = lm[u]; sa[k] = la[u]
	for k > 1 { k /= 2; pts_compose(sm[2*k], sa[2*k], sm[2*k+1], sa[2*k+1], &sm[k]) }
}
pts_chain :: proc "contextless" (h: int, pos, ends: [^]int, sm, sa: [^]i64) -> i64 {
	l, r := BASE + pos[h], BASE + ends[h]
	lm, la, rm, ra: i64 = 1, 0, 1, 0
	tmp: [2]i64
	for l < r {
		if l & 1 != 0 { pts_compose(lm, la, sm[l], sa[l], &tmp[0]); lm, la = tmp[0], tmp[1]; l += 1 }
		if r & 1 != 0 { r -= 1; pts_compose(sm[r], sa[r], rm, ra, &tmp[0]); rm, ra = tmp[0], tmp[1] }
		l /= 2; r /= 2
	}
	pts_compose(lm, la, rm, ra, &tmp[0])
	return tmp[1]
}
pts_store :: proc "contextless" (out: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for i := 0; i < 8; i += 1 { out[at+i] = u8((bits >> (8*i)) & 255) }
}

@(export)
point_set_tree_path_composite_sum_fixed_root :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > INPUT_MAX do return -1
	nr, qr := input[0], input[1]
	if nr < 1 || nr > N || qr < 1 || qr > Q do return -1
	n, q, cur := int(nr), int(qr), 2
	value: [N]i64
	for u := 0; u < n; u += 1 {
		if cur >= int(length) do return -1
		value[u] = input[cur]; cur += 1
		if value[u] < 0 || value[u] >= MOD do return -1
	}
	edge_at: [N*N]int
	for i := 0; i < N*N; i += 1 { edge_at[i] = -1 }
	eu, ev: [N-1]int
	eb, ec: [N-1]i64
	dsu, dsz: [N]int
	for u := 0; u < n; u += 1 { dsu[u], dsz[u] = u, 1 }
	for e := 0; e < n-1; e += 1 {
		if cur+4 > int(length) do return -1
		ur, vr, b, cval := input[cur], input[cur+1], input[cur+2], input[cur+3]; cur += 4
		if ur < 0 || ur >= nr || vr < 0 || vr >= nr || ur == vr || b < 1 || b >= MOD || cval < 0 || cval >= MOD do return -1
		u, v := int(ur), int(vr)
		ru, rv := pts_find(&dsu[0], u), pts_find(&dsu[0], v)
		if ru == rv do return -1
		if dsz[ru] < dsz[rv] { ru, rv = rv, ru }
		dsu[rv] = ru; dsz[ru] += dsz[rv]
		eu[e], ev[e], eb[e], ec[e] = u, v, b, cval
		edge_at[u*N+v], edge_at[v*N+u] = e, e
	}
	kind, ox, oy, oz: [Q]i64
	for i := 0; i < q; i += 1 {
		if cur >= int(length) do return -1
		kind[i] = input[cur]; cur += 1
		if kind[i] == 0 {
			if cur+2 > int(length) do return -1
			ox[i], oy[i] = input[cur], input[cur+1]; cur += 2
			if ox[i] < 0 || ox[i] >= nr || oy[i] < 0 || oy[i] >= MOD do return -1
		} else if kind[i] == 1 {
			if cur+3 > int(length) do return -1
			ox[i], oy[i], oz[i] = input[cur], input[cur+1], input[cur+2]; cur += 3
			if ox[i] < 0 || ox[i] >= nr-1 || oy[i] < 1 || oy[i] >= MOD || oz[i] < 0 || oz[i] >= MOD do return -1
		} else { return -1 }
	}
	if cur != int(length) do return -1
	bytes := 8*q
	if output == nil || capacity < c.size_t(bytes) do return -2

	parent, pedge, order, stack, sub: [N]int
	heavy: [N]int
	down: [N]i64
	for u := 0; u < n; u += 1 { parent[u], pedge[u], sub[u], heavy[u] = -2, -1, 1, -1 }
	parent[0] = -1; count, top := 0, 1; stack[0] = 0
	for top > 0 {
		top -= 1; u := stack[top]; order[count] = u; count += 1
		for v := 0; v < n; v += 1 { if edge_at[u*N+v] >= 0 && v != parent[u] { parent[v], pedge[v] = u, edge_at[u*N+v]; stack[top] = v; top += 1 } }
	}
	for i := count-1; i >= 0; i -= 1 {
		u, best := order[i], 0
		for v := 0; v < n; v += 1 { if parent[v] == u { sub[u] += sub[v]; if sub[v] > best || (sub[v] == best && (heavy[u] < 0 || v < heavy[u])) { best, heavy[u] = sub[v], v } } }
	}
	head, pos, ends, hs: [N]int
	timer, top := 0, 1; hs[0] = 0
	for top > 0 {
		top -= 1; h := hs[top]; u := h
		for {
			head[u], pos[u] = h, timer; timer += 1
			for v := 0; v < n; v += 1 { if parent[v] == u && v != heavy[u] { hs[top] = v; top += 1 } }
			if heavy[u] < 0 { break }; u = heavy[u]
		}
		ends[h] = timer
	}
	for i := count-1; i >= 0; i -= 1 {
		u := order[i]; down[u] = value[u]
		for v := 0; v < n; v += 1 { if parent[v] == u { e := pedge[v]; down[u] += eb[e]*down[v] + ec[e]*i64(sub[v]) } }
		down[u] %= MOD
	}
	lm, la: [N]i64
	for u := 0; u < n; u += 1 {
		la[u] = value[u]
		for v := 0; v < n; v += 1 { if parent[v] == u { e := pedge[v]; if heavy[u] == v { lm[u] = eb[e]; la[u] += ec[e]*i64(sub[v]) } else { la[u] += eb[e]*down[v] + ec[e]*i64(sub[v]) } } }
		la[u] %= MOD
	}
	sm, sa: [2*BASE]i64
	for i := 0; i < 2*BASE; i += 1 { sm[i] = 1 }
	for u := 0; u < n; u += 1 { sm[BASE+pos[u]], sa[BASE+pos[u]] = lm[u], la[u] }
	tmp: [2]i64
	for i := BASE-1; i > 0; i -= 1 { pts_compose(sm[2*i],sa[2*i],sm[2*i+1],sa[2*i+1],&tmp[0]); sm[i],sa[i] = tmp[0],tmp[1] }
	current: [N]i64
	for u := 0; u < n; u += 1 { if head[u] == u { current[u] = down[u] } }
	for qi := 0; qi < q; qi += 1 {
		start: int
		if kind[qi] == 0 {
			u := int(ox[qi]); la[u] = (la[u]+oy[qi]-value[u])%MOD; if la[u] < 0 { la[u] += MOD }; value[u] = oy[qi]; pts_set(u,&pos[0],&lm[0],&la[0],&sm[0],&sa[0]); start = u
		} else {
			e := int(ox[qi]); u,v := eu[e],ev[e]; child := v; if parent[u] == v { child = u }; p := parent[child]; ob,oc := eb[e],ec[e]
			if heavy[p] == child { lm[p] = oy[qi]; la[p] = (la[p]+(oz[qi]-oc)*i64(sub[child]))%MOD } else { la[p] = (la[p]+(oy[qi]-ob)*current[child]+(oz[qi]-oc)*i64(sub[child]))%MOD }
			if la[p] < 0 { la[p] += MOD }; eb[e],ec[e] = oy[qi],oz[qi]; pts_set(p,&pos[0],&lm[0],&la[0],&sm[0],&sa[0]); start = p
		}
		u := start
		for {
			h := head[u]; old := current[h]; current[h] = pts_chain(h,&pos[0],&ends[0],&sm[0],&sa[0]); if h == 0 { break }
			p,e := parent[h],pedge[h]; la[p] = (la[p]+eb[e]*(current[h]-old))%MOD; if la[p] < 0 { la[p] += MOD }; pts_set(p,&pos[0],&lm[0],&la[0],&sm[0],&sa[0]); u = p
		}
		pts_store(output,8*qi,current[0])
	}
	return i64(bytes)
}
