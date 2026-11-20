package region_discharge_path_push_relabel_maxflow

import "core:c"

NMAX :: 8
MMAX :: 12
KMAX :: 4
INPUT_MAX :: 50

ard_reaches :: proc(n: int, allowed: [NMAX*NMAX]bool,
                    residual: [NMAX*NMAX]i64, start: int,
                    target: [NMAX]bool) -> bool {
	if target[start] do return true
	seen: [NMAX]bool
	queue: [NMAX]int
	head, tail := 0, 0
	seen[start] = true
	queue[tail] = start; tail += 1
	for head < tail {
		u := queue[head]; head += 1
		for v := 0; v < n; v += 1 {
			if !seen[v] && allowed[u*NMAX+v] && residual[u*NMAX+v] > 0 {
				if target[v] do return true
				seen[v] = true
				queue[tail] = v; tail += 1
			}
		}
	}
	return false
}

ard_find_path :: proc(n: int, in_region: [NMAX]bool, allowed: [NMAX*NMAX]bool,
					  residual: [NMAX*NMAX]i64, target: [NMAX]bool,
					  excess: [NMAX]i64, parent: ^[NMAX]int) -> int {
	for v := 0; v < NMAX; v += 1 { parent[v] = -1 }
	queue: [NMAX]int
	head, tail := 0, 0
	for v := 0; v < n; v += 1 {
		if in_region[v] && excess[v] > 0 { parent[v] = v; queue[tail] = v; tail += 1 }
	}
	for head < tail {
		u := queue[head]; head += 1
		for v := 0; v < n; v += 1 {
			if parent[v] >= 0 || !allowed[u*NMAX+v] || residual[u*NMAX+v] <= 0 do continue
			parent[v] = u
			if target[v] do return v
			queue[tail] = v; tail += 1
		}
	}
	return -1
}

ard_discharge :: proc(n, region_id, source, sink, boundary_count: int,
					 regions: [NMAX]int, boundary_by_region: [KMAX*NMAX]bool,
					 global_residual: ^[NMAX*NMAX]i64, residual: ^[NMAX*NMAX]i64,
					 excess: ^[NMAX]i64, labels: ^[NMAX]int, flow_value: i64) -> i64 {
	in_region, external, inside_terminal: [NMAX]bool
	allowed: [NMAX*NMAX]bool
	local: [NMAX*NMAX]i64
	for v := 0; v < n; v += 1 {
		in_region[v] = v != source && v != sink && regions[v] == region_id
		external[v] = boundary_by_region[region_id*NMAX+v]
		inside_terminal[v] = in_region[v] || v == source || v == sink
	}
	for u := 0; u < n; u += 1 { for v := 0; v < n; v += 1 {
		allowed[u*NMAX+v] = (inside_terminal[u] && inside_terminal[v]) ||
			(in_region[u] && external[v]) || (external[u] && in_region[v])
		if allowed[u*NMAX+v] && !(external[u] && in_region[v]) {
			local[u*NMAX+v] = global_residual[u*NMAX+v]
		}
	} }
	flow := flow_value
	for stage := 0; stage <= boundary_count; stage += 1 {
		target: [NMAX]bool
		target[sink] = true
		for v := 0; v < n; v += 1 do if external[v] && labels[v] < stage { target[v] = true }
		for {
			parent: [NMAX]int
			finish := ard_find_path(n, in_region, allowed, local, target, excess, &parent)
			if finish < 0 do break
			path: [NMAX]int
			path_len, v := 0, finish
			for { path[path_len] = v; path_len += 1; if parent[v] == v do break; v = parent[v] }
			start := path[path_len-1]
			amount := excess[start]
			for i := path_len-1; i > 0; i -= 1 { u, v := path[i], path[i-1]; if local[u*NMAX+v] < amount do amount = local[u*NMAX+v] }
			for i := path_len-1; i > 0; i -= 1 {
				u, v := path[i], path[i-1]
				local[u*NMAX+v] -= amount; local[v*NMAX+u] += amount
				residual[u*NMAX+v] -= amount; residual[v*NMAX+u] += amount
			}
			excess[start] -= amount
			if finish == sink do flow += amount else excess[finish] += amount
		}
	}
	for u := 0; u < n; u += 1 { if in_region[u] {
		next_label := boundary_count
		for stage := 0; stage <= boundary_count; stage += 1 {
			target: [NMAX]bool
			target[sink] = true
			for v := 0; v < n; v += 1 do if external[v] && labels[v] < stage { target[v] = true }
			if ard_reaches(n, allowed, local, u, target) { next_label = stage; break }
		}
		if next_label > labels[u] do labels[u] = next_label
	} }
	return flow
}

@(export)
region_discharge_path_push_relabel_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > INPUT_MAX do return -1
	rn, rm, rk, rs, rt := input[0], input[1], input[2], input[3], input[4]
	if rn < 4 || rn > NMAX || rm < 1 || rm > MMAX || rk < 2 || rk > KMAX || rk > rn-2 ||
		rs < 0 || rs >= rn || rt < 0 || rt >= rn || rs == rt || length != c.size_t(5+rn+3*rm) do return -1
	n, m, k, source, sink := int(rn), int(rm), int(rk), int(rs), int(rt)
	regions: [NMAX]int
	seen: [KMAX]bool
	capacity, residual: [NMAX*NMAX]i64
	boundary_by_region: [KMAX*NMAX]bool
	boundary: [NMAX]bool
	excess: [NMAX]i64
	labels: [NMAX]int
	at := 5
	for v := 0; v < n; v += 1 {
		raw := input[at]; at += 1
		if v == source || v == sink { if raw != -1 do return -1; regions[v] = -1 }
		else { if raw < 0 || raw >= rk do return -1; regions[v] = int(raw); seen[regions[v]] = true }
	}
	for b := 0; b < k; b += 1 do if !seen[b] do return -1
	for e := 0; e < m; e += 1 {
		ru, rv, cap := input[at], input[at+1], input[at+2]; at += 3
		if ru < 0 || ru >= rn || rv < 0 || rv >= rn || ru == rv || rv == rs || ru == rt || cap < 0 || cap > 7 do return -1
		u, v := int(ru), int(rv)
		capacity[u*NMAX+v] += cap
		if cap > 0 && regions[u] >= 0 && regions[v] >= 0 && regions[u] != regions[v] {
			boundary[u], boundary[v] = true, true
			boundary_by_region[regions[u]*NMAX+v] = true
			boundary_by_region[regions[v]*NMAX+u] = true
		}
	}
	boundary_count := 0
	for v := 0; v < n; v += 1 do if boundary[v] { boundary_count += 1 }
	if boundary_count < 2 do return -1
	for i := 0; i < NMAX*NMAX; i += 1 do residual[i] = capacity[i]
	flow: i64 = 0
	for v := 0; v < n; v += 1 {
		amount := residual[source*NMAX+v]
		if amount > 0 {
			residual[source*NMAX+v] = 0; residual[v*NMAX+source] += amount
			if v == sink do flow += amount else excess[v] += amount
		}
	}
	labels[source] = boundary_count
	for sweep := 0; sweep < 2*boundary_count*boundary_count+1; sweep += 1 {
		for b := 0; b < k; b += 1 {
			flow = ard_discharge(n,b,source,sink,boundary_count,regions,boundary_by_region,&residual,&residual,&excess,&labels,flow)
		}
		active := false
		for v := 0; v < n; v += 1 do if v != source && v != sink && excess[v] > 0 && labels[v] < boundary_count { active = true }
		if !active do return flow
	}
	return -1
}
