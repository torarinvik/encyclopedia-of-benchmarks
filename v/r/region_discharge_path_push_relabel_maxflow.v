module region_discharge_path_push_relabel_maxflow

const nmax = 8
const mmax = 12
const kmax = 4
const input_max = 50

fn ard_reaches(n int, allowed [nmax * nmax]bool, residual [nmax * nmax]i64,
	start int, target [nmax]bool) bool {
	if target[start] { return true }
	mut seen := [nmax]bool{}
	mut queue := [nmax]int{}
	mut head := 0
	mut tail := 0
	seen[start] = true
	queue[tail] = start
	tail++
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. n {
			if !seen[v] && allowed[u * nmax + v] && residual[u * nmax + v] > 0 {
				if target[v] { return true }
				seen[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
	return false
}

fn ard_find_path(n int, in_region [nmax]bool, allowed [nmax * nmax]bool,
	residual [nmax * nmax]i64, target [nmax]bool, excess [nmax]i64,
	mut parent [nmax]int) int {
	for v in 0 .. nmax { parent[v] = -1 }
	mut queue := [nmax]int{}
	mut head := 0
	mut tail := 0
	for v in 0 .. n {
		if in_region[v] && excess[v] > 0 {
			parent[v] = v
			queue[tail] = v
			tail++
		}
	}
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. n {
			if parent[v] >= 0 || !allowed[u * nmax + v] || residual[u * nmax + v] <= 0 { continue }
			parent[v] = u
			if target[v] { return v }
			queue[tail] = v
			tail++
		}
	}
	return -1
}

fn ard_discharge(n int, region_id int, source int, sink int, boundary_count int,
	regions [nmax]int, boundary_by_region [kmax * nmax]bool,
	mut residual [nmax * nmax]i64, mut excess [nmax]i64,
	mut labels [nmax]int, flow_value i64) i64 {
	mut in_region := [nmax]bool{}
	mut external := [nmax]bool{}
	mut inside_terminal := [nmax]bool{}
	mut allowed := [nmax * nmax]bool{}
	mut local := [nmax * nmax]i64{}
	for v in 0 .. n {
		in_region[v] = v != source && v != sink && regions[v] == region_id
		external[v] = boundary_by_region[region_id * nmax + v]
		inside_terminal[v] = in_region[v] || v == source || v == sink
	}
	for u in 0 .. n { for v in 0 .. n {
		allowed[u * nmax + v] = (inside_terminal[u] && inside_terminal[v]) ||
			(in_region[u] && external[v]) || (external[u] && in_region[v])
		if allowed[u * nmax + v] && !(external[u] && in_region[v]) {
			local[u * nmax + v] = residual[u * nmax + v]
		}
	} }
	mut flow := flow_value
	for stage in 0 .. boundary_count + 1 {
		mut target := [nmax]bool{}
		target[sink] = true
		for v in 0 .. n { if external[v] && labels[v] < stage { target[v] = true } }
		for {
			mut parent := [nmax]int{}
			finish := ard_find_path(n, in_region, allowed, local, target, excess, mut parent)
			if finish < 0 { break }
			mut path := [nmax]int{}
			mut path_len := 0
			mut v := finish
			for {
				path[path_len] = v
				path_len++
				if parent[v] == v { break }
				v = parent[v]
			}
			start := path[path_len - 1]
			mut amount := excess[start]
			mut i := path_len - 1
			for i > 0 {
				u, v := path[i], path[i - 1]
				if local[u * nmax + v] < amount { amount = local[u * nmax + v] }
				i--
			}
			i = path_len - 1
			for i > 0 {
				u, v := path[i], path[i - 1]
				local[u * nmax + v] -= amount
				local[v * nmax + u] += amount
				residual[u * nmax + v] -= amount
				residual[v * nmax + u] += amount
				i--
			}
			excess[start] -= amount
			if finish == sink { flow += amount } else { excess[finish] += amount }
		}
	}
	for u in 0 .. n {
		if in_region[u] {
			mut next_label := boundary_count
			for stage in 0 .. boundary_count + 1 {
				mut target := [nmax]bool{}
				target[sink] = true
				for v in 0 .. n { if external[v] && labels[v] < stage { target[v] = true } }
				if ard_reaches(n, allowed, local, u, target) { next_label = stage; break }
			}
			if next_label > labels[u] { labels[u] = next_label }
		}
	}
	return flow
}

@[export: 'region_discharge_path_push_relabel_maxflow']
pub fn region_discharge_path_push_relabel_maxflow(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 5 || length > input_max { return -1 }
	unsafe {
		raw_n, raw_m, raw_k, raw_source, raw_sink := input[0], input[1], input[2], input[3], input[4]
		if raw_n < 4 || raw_n > nmax || raw_m < 1 || raw_m > mmax || raw_k < 2 || raw_k > kmax || raw_k > raw_n - 2 ||
			raw_source < 0 || raw_source >= raw_n || raw_sink < 0 || raw_sink >= raw_n || raw_source == raw_sink ||
			length != usize(5 + raw_n + 3 * raw_m) { return -1 }
		n, m, k, source, sink := int(raw_n), int(raw_m), int(raw_k), int(raw_source), int(raw_sink)
		mut regions := [nmax]int{}
		mut seen := [kmax]bool{}
		mut capacity := [nmax * nmax]i64{}
		mut residual := [nmax * nmax]i64{}
		mut boundary_by_region := [kmax * nmax]bool{}
		mut boundary := [nmax]bool{}
		mut excess := [nmax]i64{}
		mut labels := [nmax]int{}
		mut at := 5
		for v in 0 .. n {
			raw := input[at]
			at++
			if v == source || v == sink {
				if raw != -1 { return -1 }
				regions[v] = -1
			} else {
				if raw < 0 || raw >= raw_k { return -1 }
				regions[v] = int(raw)
				seen[regions[v]] = true
			}
		}
		for b in 0 .. k { if !seen[b] { return -1 } }
		for e in 0 .. m {
			p := 5 + n + 3 * e
			ru, rv, cap := input[p], input[p + 1], input[p + 2]
			if ru < 0 || ru >= raw_n || rv < 0 || rv >= raw_n || ru == rv || rv == raw_source || ru == raw_sink || cap < 0 || cap > 7 { return -1 }
			u, v := int(ru), int(rv)
			capacity[u * nmax + v] += cap
			if cap > 0 && regions[u] >= 0 && regions[v] >= 0 && regions[u] != regions[v] {
				boundary[u], boundary[v] = true, true
				boundary_by_region[regions[u] * nmax + v] = true
				boundary_by_region[regions[v] * nmax + u] = true
			}
		}
		mut boundary_count := 0
		for v in 0 .. n { if boundary[v] { boundary_count++ } }
		if boundary_count < 2 { return -1 }
		residual = capacity
		mut flow := i64(0)
		for v in 0 .. n {
			amount := residual[source * nmax + v]
			if amount > 0 {
				residual[source * nmax + v] = 0
				residual[v * nmax + source] += amount
				if v == sink { flow += amount } else { excess[v] += amount }
			}
		}
		labels[source] = boundary_count
		for _ in 0 .. 2 * boundary_count * boundary_count + 1 {
			for b in 0 .. k { flow = ard_discharge(n, b, source, sink, boundary_count, regions, boundary_by_region, mut residual, mut excess, mut labels, flow) }
			mut active := false
			for v in 0 .. n { if v != source && v != sink && excess[v] > 0 && labels[v] < boundary_count { active = true } }
			if !active { return flow }
		}
		return -1
	}
}
