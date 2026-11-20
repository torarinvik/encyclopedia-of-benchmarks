package eibfs_maxflow

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

@(export)
eibfs_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
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
