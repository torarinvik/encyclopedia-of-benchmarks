// Dinic maximum flow using BFS level graphs and blocking-flow DFS.
fn dinic_maxflow_dfs(u int, sink int, pushed i64, mut residual [][]i64, level []int, mut next []int, n int) i64 {
	if u == sink { return pushed }
	for next[u] < n {
		v := next[u]
		if level[v] == level[u] + 1 && residual[u][v] > 0 {
			sent := dinic_maxflow_dfs(v, sink, min(pushed, residual[u][v]), mut residual, level, mut next, n)
			if sent > 0 { residual[u][v] -= sent; residual[v][u] += sent; return sent }
		}
		next[u]++
	}
	return 0
}

@[export: 'dinic_maxflow']
pub fn dinic_maxflow(input &i64, length usize) i64 {
	if length < 4 { return -1 }
	unsafe {
		nv := input[0]; mv := input[1]; sv := input[2]; tv := input[3]
		if nv < 2 || nv > 16 || mv < 0 || mv > 64 || sv < 1 || sv > nv || tv < 1 || tv > nv || sv == tv { return -1 }
		n := int(nv); m := int(mv); s := int(sv - 1); t := int(tv - 1)
		if length != usize(4 + 3*m) { return -1 }
		mut residual := [][]i64{len: n, init: []i64{len: n, init: 0}}
		for i := 0; i < m; i++ {
			u := input[4+3*i]; v := input[5+3*i]; cap := input[6+3*i]
			if u < 1 || u > nv || v < 1 || v > nv || u == v || cap < 0 || cap > 100 { return -1 }
			residual[int(u-1)][int(v-1)] += cap
		}
		mut flow := i64(0)
		for {
			mut level := []int{len: n, init: -1}; mut queue := []int{len: n, init: 0}
			mut head := 0; mut tail := 0; level[s] = 0; queue[tail] = s; tail++
			for head < tail { u := queue[head]; head++; for v := 0; v < n; v++ { if residual[u][v] > 0 && level[v] < 0 { level[v] = level[u]+1; queue[tail] = v; tail++ } } }
			if level[t] < 0 { break }
			mut next := []int{len: n, init: 0}
			for { pushed := dinic_maxflow_dfs(s,t,6401,mut residual,level,mut next,n); if pushed == 0 { break }; flow += pushed }
		}
		return flow
	}
}
