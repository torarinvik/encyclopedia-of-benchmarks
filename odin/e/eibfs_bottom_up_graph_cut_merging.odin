package eibfs_bottom_up_graph_cut_merging

import "core:c"

N_MAX :: 8
M_MAX :: 24
INPUT_MAX :: 77
FREE_TREE :: 0
S_TREE :: 1
T_TREE :: 2

State :: struct {
    n, source, sink: int,
    forward: bool,
    kind, parent: [8]int,
    original, residual: [64]i64,
    balance, ds, dt: [8]i64,
    ds_max, dt_max: i64,
    orphaned: [8]bool,
    events: int,
}

root :: proc(s: ^State, vertex: int) -> int {
    v := vertex
    for 0..<s.n {
        if s.parent[v] < 0 do return v
        v = s.parent[v]
    }
    return -1
}

bottleneck :: proc(s: ^State, vertex, kind: int) -> i64 {
    v := vertex
    answer: i64 = 2401
    for 0..<s.n {
        p := s.parent[v]
        if p < 0 do return answer
        cap := s.residual[p*8+v]
        if kind == T_TREE do cap = s.residual[v*8+p]
        if cap < answer do answer = cap
        v = p
    }
    return 0
}

push :: proc(s: ^State, u, v: int, amount: i64) {
    s.residual[u*8+v] -= amount
    s.residual[v*8+u] += amount
    if u != s.source && u != s.sink do s.balance[u] -= amount
    if v != s.source && v != s.sink do s.balance[v] += amount
}

mark :: proc(s: ^State, v: int, q: ^[512]int, tail: ^int) {
    if !s.orphaned[v] { s.orphaned[v] = true; q[tail^] = v; tail^ += 1 }
}

detach :: proc(s: ^State, v, kind: int, q: ^[512]int, tail: ^int) {
    for child := 0; child < s.n; child += 1 {
        if s.kind[child] == kind && s.parent[child] == v { s.parent[child] = -1; mark(s, child, q, tail) }
    }
}

adopt :: proc(s: ^State, v, kind: int, q: ^[512]int, tail: ^int) {
    sink_side := kind == T_TREE
    s.orphaned[v] = false
    old := s.ds[v]
    if sink_side do old = s.dt[v]
    for u := 0; u < s.n; u += 1 {
        cap := s.residual[u*8+v]
        here, label := s.ds[v], s.ds[u]
        if sink_side { cap = s.residual[v*8+u]; here, label = s.dt[v], s.dt[u] }
        if u != v && s.kind[u] == kind && cap > 0 && here == label + 1 { s.parent[v] = u; return }
    }
    frontier := s.ds_max
    subtract := !s.forward
    if sink_side { frontier, subtract = s.dt_max, s.forward }
    limit := frontier
    if subtract do limit -= 1
    best: i64 = i64(4*s.n)
    for u := 0; u < s.n; u += 1 {
        cap := s.residual[u*8+v]
        label := s.ds[u]
        if sink_side { cap, label = s.residual[v*8+u], s.dt[u] }
        if u != v && s.kind[u] == kind && cap > 0 && label <= limit && label < best do best = label
    }
    parent := -1
    for u := 0; u < s.n; u += 1 {
        cap := s.residual[u*8+v]
        label := s.ds[u]
        if sink_side { cap, label = s.residual[v*8+u], s.dt[u] }
        if u != v && s.kind[u] == kind && cap > 0 && label == best { parent = u; break }
    }
    if parent >= 0 && best + 1 > old {
        detach(s, v, kind, q, tail)
        s.parent[v] = parent
        if sink_side do s.dt[v] = best + 1 else s.ds[v] = best + 1
        return
    }
    detach(s, v, kind, q, tail)
    s.parent[v], s.kind[v] = -1, FREE_TREE
    if sink_side && s.balance[v] > 0 {
        label_add := 0
        if s.forward do label_add = 1
        s.kind[v], s.ds[v] = S_TREE, s.ds_max + i64(label_add)
    }
    if !sink_side && s.balance[v] < 0 {
        label_add := 0
        if !s.forward do label_add = 1
        s.kind[v], s.dt[v] = T_TREE, s.dt_max + i64(label_add)
    }
}

repair_orphans :: proc(s: ^State, kind: int, q: ^[512]int, head: int, tail: ^int) {
    for head < tail^ {
        v := q[head]; head += 1
        s.orphaned[v] = false
        if s.kind[v] == kind do adopt(s, v, kind, q, tail)
    }
}

drain :: proc(s: ^State, vertex, kind: int) {
    root_v := root(s, vertex)
    if root_v < 0 do return
    q: [512]int
    head, tail, x := 0, 0, vertex
    for (kind == T_TREE && s.balance[x] > 0 || kind == S_TREE && s.balance[x] < 0) && s.parent[x] >= 0 {
        p := s.parent[x]
        cap, need := s.residual[p*8+x], -s.balance[x]
        if kind == T_TREE { cap, need = s.residual[x*8+p], s.balance[x] }
        amount := cap
        if need < amount do amount = need
        if amount > 0 { if kind == T_TREE do push(s,x,p,amount) else push(s,p,x,amount) }
        after, remaining := -s.balance[x], s.residual[p*8+x]
        if kind == T_TREE { after, remaining = s.balance[x], s.residual[x*8+p] }
        if remaining == 0 && after >= 0 { s.parent[x] = -1; mark(s,x,&q,&tail); break }
        if after == 0 do break
        x = p
    }
    if kind == T_TREE && root_v != s.sink && s.kind[root_v] == kind && s.balance[root_v] >= 0 { s.parent[root_v] = -1; mark(s,root_v,&q,&tail) }
    if kind == S_TREE && root_v != s.source && s.kind[root_v] == kind && s.balance[root_v] <= 0 { s.parent[root_v] = -1; mark(s,root_v,&q,&tail) }
    repair_orphans(s,kind,&q,head,&tail)
}

repair :: proc(s: ^State) {
    for {
        found := false
        for v := 0; v < s.n; v += 1 { if s.kind[v] == T_TREE && s.balance[v] > 0 { drain(s,v,T_TREE); found = true; break } }
        if found do continue
        for v := 0; v < s.n; v += 1 { if s.kind[v] == S_TREE && s.balance[v] < 0 { drain(s,v,S_TREE); found = true; break } }
        if !found do return
    }
}

augment :: proc(s: ^State, v, w: int) -> bool {
    rs, rt := root(s,v), root(s,w)
    if rs < 0 || rt < 0 || s.residual[v*8+w] <= 0 do return false
    c, bs, bt := s.residual[v*8+w], bottleneck(s,v,S_TREE), bottleneck(s,w,T_TREE)
    amount := c
    if rs == s.source && rt == s.sink {} else if rs == s.source { amount = min(bs,c) }
    else if rt == s.sink { amount = min(c,bt) }
    else { amount = min(s.balance[rs],bs); amount = min(amount,c); amount = min(amount,bt); amount = min(amount,-s.balance[rt]) }
    if amount <= 0 do return false
    push(s,v,w,amount); repair(s); return true
}

solve :: proc(s: ^State) -> i64 {
    finished := false
    for phase := 0; phase < 4*s.n+4; phase += 1 {
        if finished do break
        for {
            restart := false
            if s.forward {
                for v := 0; v < s.n && !restart; v += 1 {
                    if s.kind[v] != S_TREE || s.ds[v] != s.ds_max do continue
                    for w := 0; w < s.n; w += 1 {
                        if s.residual[v*8+w] <= 0 || s.kind[w] == S_TREE do continue
                        if s.kind[w] == FREE_TREE { s.kind[w],s.parent[w],s.ds[w] = S_TREE,v,s.ds_max+1 }
                        else if s.kind[w] == T_TREE && augment(s,v,w) { s.events += 1; if s.events > 100000 do return -1; restart=true; break }
                    }
                }
                if !restart {
                    next := false
                    for v := 0; v < s.n; v += 1 { if s.kind[v]==S_TREE && s.ds[v]==s.ds_max+1 do next=true }
                    if next do s.ds_max += 1 else finished=true
                    break
                }
            } else {
                for w := 0; w < s.n && !restart; w += 1 {
                    if s.kind[w] != T_TREE || s.dt[w] != s.dt_max do continue
                    for v := 0; v < s.n; v += 1 {
                        if s.residual[v*8+w] <= 0 || s.kind[v] == T_TREE do continue
                        if s.kind[v] == FREE_TREE { s.kind[v],s.parent[v],s.dt[v] = T_TREE,w,s.dt_max+1 }
                        else if s.kind[v] == S_TREE && augment(s,v,w) { s.events += 1; if s.events > 100000 do return -1; restart=true; break }
                    }
                }
                if !restart {
                    next := false
                    for v := 0; v < s.n; v += 1 { if s.kind[v]==T_TREE && s.dt[v]==s.dt_max+1 do next=true }
                    if next do s.dt_max += 1 else finished=true
                    break
                }
            }
        }
        if !finished do s.forward = !s.forward
    }
    reachable: [8]bool
    queue: [8]int
    head, tail := 0, 0
    for v := 0; v < s.n; v += 1 { if s.kind[v] == S_TREE { reachable[v] = true; queue[tail] = v; tail += 1 } }
    for head < tail {
        u := queue[head]; head += 1
        for v := 0; v < s.n; v += 1 { if s.residual[u*8+v] > 0 && !reachable[v] { reachable[v] = true; queue[tail] = v; tail += 1 } }
    }
    cut: i64 = 0
    for u := 0; u < s.n; u += 1 { if reachable[u] { for v := 0; v < s.n; v += 1 { if !reachable[v] do cut += s.original[u*8+v] } } }
    return cut
}

eibfs_maxflow_frame :: proc (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > c.size_t(INPUT_MAX) do return -1
    nv,mv,sv,tv := input[0],input[1],input[2],input[3]
    if nv < 2 || nv > N_MAX || mv < 0 || mv > M_MAX || sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv do return -1
    n,m,source,sink := int(nv),int(mv),int(sv),int(tv)
    if length != c.size_t(4+3*m) do return -1
    s := State{n=n,source=source,sink=sink,forward=true}
    for v := 0; v < n; v += 1 { s.parent[v] = -1 }
    for e := 0; e < m; e += 1 {
        u,v,capa := input[4+3*e],input[5+3*e],input[6+3*e]
        if u < 0 || u >= nv || v < 0 || v >= nv || u == v || capa < 0 || capa > 100 do return -1
        s.original[int(u)*8+int(v)] += capa; s.residual[int(u)*8+int(v)] += capa
    }
    s.kind[source],s.kind[sink] = S_TREE,T_TREE
    return solve(&s)
}

peibfs_find :: proc(parent: [4]int, block: int) -> int {
    root := block
    for 0..<4 {
        if parent[root] == root do return root
        root = parent[root]
    }
    return root
}

peibfs_component_flow :: proc(n, m: int, active: [4]bool, block_ids: [6]int,
    source_caps, sink_caps: [6]i64, edge_u, edge_v: [6]int, edge_uv, edge_vu: [6]i64) -> i64 {
    local: [6]int
    vertices: [6]int
    for v := 0; v < n; v += 1 { local[v] = -1 }
    k := 0
    for v := 0; v < n; v += 1 {
        if active[block_ids[v]] { local[v] = k; vertices[k] = v; k += 1 }
    }
    internal_edges := 0
    for e := 0; e < m; e += 1 { if local[edge_u[e]] >= 0 && local[edge_v[e]] >= 0 { internal_edges += 1 } }
    frame: [77]i64
    source, sink := k, k + 1
    frame[0], frame[1], frame[2], frame[3] = i64(k + 2), i64(2*k + 2*internal_edges), i64(source), i64(sink)
    at := 4
    for i := 0; i < k; i += 1 {
        v := vertices[i]
        frame[at], frame[at+1], frame[at+2] = i64(source), i64(i), source_caps[v]
        at += 3
        frame[at], frame[at+1], frame[at+2] = i64(i), i64(sink), sink_caps[v]
        at += 3
    }
    for e := 0; e < m; e += 1 {
        u, v := edge_u[e], edge_v[e]
        if local[u] >= 0 && local[v] >= 0 {
            frame[at], frame[at+1], frame[at+2] = i64(local[u]), i64(local[v]), edge_uv[e]
            at += 3
            frame[at], frame[at+1], frame[at+2] = i64(local[v]), i64(local[u]), edge_vu[e]
            at += 3
        }
    }
    return eibfs_maxflow_frame(cast([^]i64)&frame[0], c.size_t(at))
}

@(export)
eibfs_bottom_up_graph_cut_merging :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 46 do return -1
    nv, mv, bv := input[0], input[1], input[2]
    if nv < 2 || nv > 6 || mv < 0 || mv > 6 || bv < 1 || bv > 4 || bv > nv do return -1
    n, m, blocks := int(nv), int(mv), int(bv)
    if length != c.size_t(3+3*n+4*m) do return -1
    block_ids: [6]int
    source_caps, sink_caps: [6]i64
    edge_u, edge_v: [6]int
    edge_uv, edge_vu: [6]i64
    present: [4]bool
    for v := 0; v < n; v += 1 {
        block, sc, tc := input[3+v], input[3+n+v], input[3+2*n+v]
        if block < 0 || block >= bv || sc < 0 || sc > 7 || tc < 0 || tc > 7 do return -1
        block_ids[v], source_caps[v], sink_caps[v] = int(block), sc, tc
        present[int(block)] = true
    }
    for b := 0; b < blocks; b += 1 { if !present[b] do return -1 }
    edges_at := 3+3*n
    for e := 0; e < m; e += 1 {
        u, v := input[edges_at+4*e], input[edges_at+4*e+1]
        uv, vu := input[edges_at+4*e+2], input[edges_at+4*e+3]
        if u < 0 || u >= nv || v < 0 || v >= nv || u == v || uv < 0 || uv > 7 || vu < 0 || vu > 7 do return -1
        edge_u[e], edge_v[e], edge_uv[e], edge_vu[e] = int(u), int(v), uv, vu
    }

    tags: [6]int
    component_flow: [4]i64
    active: [4]bool
    for b := 0; b < blocks; b += 1 {
        vertices: [6]int
        local: [6]int
        for v := 0; v < n; v += 1 { local[v] = -1 }
        k := 0
        for v := 0; v < n; v += 1 {
            if block_ids[v] == b { vertices[k], local[v] = v, k; k += 1 }
        }
        best_cost := i64(9223372036854775807)
        best_mask := 0
        for mask := 0; mask < (1<<k); mask += 1 {
            cost: i64 = 0
            for i := 0; i < k; i += 1 {
                v := vertices[i]
                if (mask & (1<<i)) != 0 { cost += sink_caps[v] } else { cost += source_caps[v] }
            }
            for e := 0; e < m; e += 1 {
                u, v := edge_u[e], edge_v[e]
                ui, vi := local[u], local[v]
                if ui >= 0 && vi >= 0 {
                    u_side, v_side := (mask & (1<<ui)) != 0, (mask & (1<<vi)) != 0
                    if u_side && !v_side { cost += edge_uv[e] } else if v_side && !u_side { cost += edge_vu[e] }
                }
            }
            if cost < best_cost { best_cost, best_mask = cost, mask }
        }
        for i := 0; i < k; i += 1 { if (best_mask & (1<<i)) != 0 { tags[vertices[i]] = 1 } else { tags[vertices[i]] = 2 } }
        active[b] = true
        component_flow[b] = peibfs_component_flow(n, m, active, block_ids, source_caps, sink_caps, edge_u, edge_v, edge_uv, edge_vu)
        if component_flow[b] < 0 do return -1
        active[b] = false
    }

    pair_a, pair_b: [6]int
    pair_score: [6]i64
    pair_count := 0
    for e := 0; e < m; e += 1 {
        u, v := edge_u[e], edge_v[e]
        a0, b0 := block_ids[u], block_ids[v]
        if a0 == b0 || (edge_uv[e] == 0 && edge_vu[e] == 0) do continue
        a, b := a0, b0
        if a > b { a, b = b, a }
        found := -1
        for i := 0; i < pair_count; i += 1 { if pair_a[i] == a && pair_b[i] == b { found = i } }
        if found < 0 { found = pair_count; pair_count += 1; pair_a[found], pair_b[found] = a, b }
        if tags[u] != tags[v] { if edge_uv[e] > 0 { pair_score[found] += 1 }; if edge_vu[e] > 0 { pair_score[found] += 1 } }
    }
    for i := 0; i < pair_count; i += 1 {
        for j := i+1; j < pair_count; j += 1 {
            precedes := pair_score[j] > pair_score[i] || (pair_score[j] == pair_score[i] && (pair_a[j] < pair_a[i] || (pair_a[j] == pair_a[i] && pair_b[j] < pair_b[i])))
            if precedes {
                pair_a[i], pair_a[j] = pair_a[j], pair_a[i]
                pair_b[i], pair_b[j] = pair_b[j], pair_b[i]
                pair_score[i], pair_score[j] = pair_score[j], pair_score[i]
            }
        }
    }
    parent: [4]int
    for b := 0; b < blocks; b += 1 { parent[b] = b }
    for i := 0; i < pair_count; i += 1 {
        root_a, root_b := peibfs_find(parent, pair_a[i]), peibfs_find(parent, pair_b[i])
        if root_a == root_b do continue
        root, other := root_a, root_b
        if root > other { root, other = other, root }
        parent[other] = root
        for b := 0; b < blocks; b += 1 { active[b] = peibfs_find(parent, b) == root }
        component_flow[root] = peibfs_component_flow(n, m, active, block_ids, source_caps, sink_caps, edge_u, edge_v, edge_uv, edge_vu)
        if component_flow[root] < 0 do return -1
        component_flow[other] = 0
    }
    answer: i64 = 0
    for b := 0; b < blocks; b += 1 { if peibfs_find(parent, b) == b { answer += component_flow[b] } }
    return answer
}
