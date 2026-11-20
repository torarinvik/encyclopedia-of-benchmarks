/* Clean-room bounded Excesses IBFS maximum flow. */
const NMAX: usize = 8;
const MMAX: usize = 24;
const INPUT_MAX: usize = 77;
const EVENT_MAX: usize = 100_000;
const FREE_TREE: i32 = 0;
const S_TREE: i32 = 1;
const T_TREE: i32 = 2;

struct State {
    n: usize, source: usize, sink: usize, forward: bool,
    kind: [i32; NMAX], parent: [i32; NMAX],
    original: [[i64; NMAX]; NMAX], residual: [[i64; NMAX]; NMAX],
    balance: [i64; NMAX], ds: [i64; NMAX], dt: [i64; NMAX],
    ds_max: i64, dt_max: i64, orphaned: [bool; NMAX], events: usize,
}

impl State {
    fn root(&self, mut v: usize) -> i32 {
        for _ in 0..self.n {
            if self.parent[v] < 0 { return v as i32; }
            v = self.parent[v] as usize;
        }
        -1
    }
    fn bottleneck(&self, mut v: usize, kind: i32) -> i64 {
        let mut answer = 2401i64;
        for _ in 0..self.n {
            let p = self.parent[v];
            if p < 0 { return answer; }
            let parent = p as usize;
            answer = answer.min(if kind == S_TREE { self.residual[parent][v] } else { self.residual[v][parent] });
            v = parent;
        }
        0
    }
    fn push(&mut self, u: usize, v: usize, amount: i64) {
        self.residual[u][v] -= amount;
        self.residual[v][u] += amount;
        if u != self.source && u != self.sink { self.balance[u] -= amount; }
        if v != self.source && v != self.sink { self.balance[v] += amount; }
    }
    fn mark_orphan(&mut self, v: usize, queue: &mut [usize; 512], tail: &mut usize) {
        if !self.orphaned[v] { self.orphaned[v] = true; queue[*tail] = v; *tail += 1; }
    }
    fn detach_children(&mut self, v: usize, kind: i32, queue: &mut [usize; 512], tail: &mut usize) {
        for child in 0..self.n {
            if self.kind[child] == kind && self.parent[child] == v as i32 {
                self.parent[child] = -1; self.mark_orphan(child, queue, tail);
            }
        }
    }
    fn adopt_t(&mut self, v: usize, queue: &mut [usize; 512], tail: &mut usize) {
        self.orphaned[v] = false;
        let old = self.dt[v];
        for u in 0..self.n {
            if u != v && self.kind[u] == T_TREE && self.residual[v][u] > 0 && self.dt[v] == self.dt[u] + 1 {
                self.parent[v] = u as i32; return;
            }
        }
        let limit = self.dt_max - if self.forward { 1 } else { 0 };
        let mut best = (4 * self.n) as i64;
        for u in 0..self.n {
            if u != v && self.kind[u] == T_TREE && self.residual[v][u] > 0 && self.dt[u] <= limit { best = best.min(self.dt[u]); }
        }
        let parent = (0..self.n).find(|&u| u != v && self.kind[u] == T_TREE && self.residual[v][u] > 0 && self.dt[u] == best);
        if let Some(u) = parent {
            if best + 1 > old {
                self.detach_children(v, T_TREE, queue, tail);
                self.parent[v] = u as i32; self.dt[v] = best + 1; return;
            }
        }
        self.detach_children(v, T_TREE, queue, tail);
        self.parent[v] = -1; self.kind[v] = FREE_TREE;
        if self.balance[v] > 0 { self.kind[v] = S_TREE; self.ds[v] = self.ds_max + if self.forward { 1 } else { 0 }; }
    }
    fn adopt_s(&mut self, v: usize, queue: &mut [usize; 512], tail: &mut usize) {
        self.orphaned[v] = false;
        let old = self.ds[v];
        for u in 0..self.n {
            if u != v && self.kind[u] == S_TREE && self.residual[u][v] > 0 && self.ds[v] == self.ds[u] + 1 {
                self.parent[v] = u as i32; return;
            }
        }
        let limit = self.ds_max - if self.forward { 0 } else { 1 };
        let mut best = (4 * self.n) as i64;
        for u in 0..self.n {
            if u != v && self.kind[u] == S_TREE && self.residual[u][v] > 0 && self.ds[u] <= limit { best = best.min(self.ds[u]); }
        }
        let parent = (0..self.n).find(|&u| u != v && self.kind[u] == S_TREE && self.residual[u][v] > 0 && self.ds[u] == best);
        if let Some(u) = parent {
            if best + 1 > old {
                self.detach_children(v, S_TREE, queue, tail);
                self.parent[v] = u as i32; self.ds[v] = best + 1; return;
            }
        }
        self.detach_children(v, S_TREE, queue, tail);
        self.parent[v] = -1; self.kind[v] = FREE_TREE;
        if self.balance[v] < 0 { self.kind[v] = T_TREE; self.dt[v] = self.dt_max + if self.forward { 0 } else { 1 }; }
    }
    fn repair_orphans(&mut self, kind: i32, queue: &mut [usize; 512], mut head: usize, tail: &mut usize) {
        while head < *tail {
            let v = queue[head]; head += 1; self.orphaned[v] = false;
            if self.kind[v] == kind {
                if kind == T_TREE { self.adopt_t(v, queue, tail); } else { self.adopt_s(v, queue, tail); }
            }
        }
    }
    fn drain_t(&mut self, v: usize) {
        let root = self.root(v); if root < 0 { return; }
        let mut queue = [0usize; 512]; let (mut head, mut tail) = (0usize, 0usize); let mut x = v;
        while self.balance[x] > 0 && self.parent[x] >= 0 {
            let p = self.parent[x] as usize; let amount = self.balance[x].min(self.residual[x][p]);
            if amount > 0 { self.push(x, p, amount); }
            if self.residual[x][p] == 0 && self.balance[x] >= 0 { self.parent[x] = -1; self.mark_orphan(x, &mut queue, &mut tail); break; }
            if self.balance[x] == 0 { break; } x = p;
        }
        let r = root as usize;
        if r != self.sink && self.kind[r] == T_TREE && self.balance[r] >= 0 { self.parent[r] = -1; self.mark_orphan(r, &mut queue, &mut tail); }
        self.repair_orphans(T_TREE, &mut queue, head, &mut tail);
    }
    fn drain_s(&mut self, v: usize) {
        let root = self.root(v); if root < 0 { return; }
        let mut queue = [0usize; 512]; let (mut head, mut tail) = (0usize, 0usize); let mut x = v;
        while self.balance[x] < 0 && self.parent[x] >= 0 {
            let p = self.parent[x] as usize; let amount = (-self.balance[x]).min(self.residual[p][x]);
            if amount > 0 { self.push(p, x, amount); }
            if self.residual[p][x] == 0 && self.balance[x] <= 0 { self.parent[x] = -1; self.mark_orphan(x, &mut queue, &mut tail); break; }
            if self.balance[x] == 0 { break; } x = p;
        }
        let r = root as usize;
        if r != self.source && self.kind[r] == S_TREE && self.balance[r] <= 0 { self.parent[r] = -1; self.mark_orphan(r, &mut queue, &mut tail); }
        self.repair_orphans(S_TREE, &mut queue, head, &mut tail);
    }
    fn repair(&mut self) {
        loop {
            let mut found = false;
            for v in 0..self.n { if self.kind[v] == T_TREE && self.balance[v] > 0 { self.drain_t(v); found = true; break; } }
            if found { continue; }
            for v in 0..self.n { if self.kind[v] == S_TREE && self.balance[v] < 0 { self.drain_s(v); found = true; break; } }
            if !found { return; }
        }
    }
    fn augment(&mut self, v: usize, w: usize) -> bool {
        let rs = self.root(v); let rt = self.root(w);
        if rs < 0 || rt < 0 || self.residual[v][w] <= 0 { return false; }
        let (rs, rt) = (rs as usize, rt as usize);
        let connector = self.residual[v][w]; let bs = self.bottleneck(v, S_TREE); let bt = self.bottleneck(w, T_TREE);
        let amount = if rs == self.source && rt == self.sink { connector }
            else if rs == self.source { bs.min(connector) }
            else if rt == self.sink { connector.min(bt) }
            else { self.balance[rs].min(bs).min(connector).min(bt).min(-self.balance[rt]) };
        if amount <= 0 { return false; }
        self.push(v, w, amount); self.repair(); true
    }
    fn run(&mut self) -> i64 {
        for phase in 0..(4 * self.n + 4) {
            let mut finished = false;
            loop {
                let mut restart = false;
                if self.forward {
                    'scan_s: for v in 0..self.n {
                        if self.kind[v] != S_TREE || self.ds[v] != self.ds_max { continue; }
                        for w in 0..self.n {
                            if self.residual[v][w] <= 0 || self.kind[w] == S_TREE { continue; }
                            if self.kind[w] == FREE_TREE { self.kind[w] = S_TREE; self.parent[w] = v as i32; self.ds[w] = self.ds_max + 1; }
                            else if self.kind[w] == T_TREE {
                                if self.augment(v, w) { self.events += 1; if self.events > EVENT_MAX { return -1; } restart = true; break 'scan_s; }
                            }
                        }
                    }
                    if !restart && !(0..self.n).any(|v| self.kind[v] == S_TREE && self.ds[v] == self.ds_max + 1) { finished = true; break; }
                    if !restart { self.ds_max += 1; break; }
                } else {
                    'scan_t: for w in 0..self.n {
                        if self.kind[w] != T_TREE || self.dt[w] != self.dt_max { continue; }
                        for v in 0..self.n {
                            if self.residual[v][w] <= 0 || self.kind[v] == T_TREE { continue; }
                            if self.kind[v] == FREE_TREE { self.kind[v] = T_TREE; self.parent[v] = w as i32; self.dt[v] = self.dt_max + 1; }
                            else if self.kind[v] == S_TREE {
                                if self.augment(v, w) { self.events += 1; if self.events > EVENT_MAX { return -1; } restart = true; break 'scan_t; }
                            }
                        }
                    }
                    if !restart && !(0..self.n).any(|v| self.kind[v] == T_TREE && self.dt[v] == self.dt_max + 1) { finished = true; break; }
                    if !restart { self.dt_max += 1; break; }
                }
                if !restart { break; }
            }
            if finished { break; }
            if phase + 1 < 4 * self.n + 4 { self.forward = !self.forward; }
        }
        let mut reachable = [false; NMAX]; let mut queue = [0usize; NMAX];
        let (mut head, mut tail) = (0usize, 0usize);
        for v in 0..self.n { if self.kind[v] == S_TREE { reachable[v] = true; queue[tail] = v; tail += 1; } }
        while head < tail { let u = queue[head]; head += 1; for v in 0..self.n {
            if self.residual[u][v] > 0 && !reachable[v] { reachable[v] = true; queue[tail] = v; tail += 1; }
        } }
        let mut cut = 0;
        for u in 0..self.n { if reachable[u] { for v in 0..self.n { if !reachable[v] { cut += self.original[u][v]; } } } }
        cut
    }
}

#[no_mangle]
pub unsafe extern "C" fn eibfs_maxflow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > INPUT_MAX { return -1; }
    let n64 = *input; let m64 = *input.add(1); let s64 = *input.add(2); let t64 = *input.add(3);
    if !(2..=NMAX as i64).contains(&n64) || !(0..=MMAX as i64).contains(&m64) || s64 < 0 || s64 >= n64 || t64 < 0 || t64 >= n64 || s64 == t64 || length != 4 + 3 * m64 as usize { return -1; }
    let (n, source, sink, m) = (n64 as usize, s64 as usize, t64 as usize, m64 as usize);
    let mut state = State { n, source, sink, forward: true, kind: [FREE_TREE; NMAX], parent: [-1; NMAX], original: [[0; NMAX]; NMAX], residual: [[0; NMAX]; NMAX], balance: [0; NMAX], ds: [0; NMAX], dt: [0; NMAX], ds_max: 0, dt_max: 0, orphaned: [false; NMAX], events: 0 };
    for e in 0..m {
        let u = *input.add(4 + 3 * e); let v = *input.add(5 + 3 * e); let c = *input.add(6 + 3 * e);
        if u < 0 || u >= n64 || v < 0 || v >= n64 || u == v || !(0..=100).contains(&c) { return -1; }
        state.original[u as usize][v as usize] += c; state.residual[u as usize][v as usize] += c;
    }
    state.kind[source] = S_TREE; state.kind[sink] = T_TREE;
    state.run()
}

const MERGE_NMAX: usize = 6;
const MERGE_MMAX: usize = 6;
const MERGE_INPUT_MAX: usize = 46;
#[derive(Clone, Copy)]
struct MergeEdge { u: usize, v: usize, uv: i64, vu: i64 }

fn merge_find(parent: &mut [usize; 4], mut x: usize) -> usize {
    while parent[x] != x { let next = parent[x]; let grand = parent[next]; parent[x] = grand; x = grand; }
    x
}

unsafe fn merge_component_flow(n: usize, active: &[bool; 6], source_caps: &[i64; 6],
                               sink_caps: &[i64; 6], edges: &[MergeEdge; 6], m: usize) -> i64 {
    let mut local = [-1i64; 6];
    let mut k = 0usize;
    for v in 0..n { if active[v] { local[v] = k as i64; k += 1; } }
    let mut frame = [0i64; 76];
    let source = k; let sink = k + 1;
    frame[0] = (k + 2) as i64; frame[2] = source as i64; frame[3] = sink as i64;
    let mut at = 4usize; let mut arc_count = 0usize;
    for v in 0..n { if active[v] {
        frame[at] = source as i64; at += 1; frame[at] = local[v]; at += 1; frame[at] = source_caps[v]; at += 1; arc_count += 1;
        frame[at] = local[v]; at += 1; frame[at] = sink as i64; at += 1; frame[at] = sink_caps[v]; at += 1; arc_count += 1;
    } }
    for e in 0..m { if local[edges[e].u] >= 0 && local[edges[e].v] >= 0 {
        frame[at] = local[edges[e].u]; at += 1; frame[at] = local[edges[e].v]; at += 1; frame[at] = edges[e].uv; at += 1; arc_count += 1;
        frame[at] = local[edges[e].v]; at += 1; frame[at] = local[edges[e].u]; at += 1; frame[at] = edges[e].vu; at += 1; arc_count += 1;
    } }
    frame[1] = arc_count as i64;
    unsafe { eibfs_maxflow(frame.as_ptr(), at) }
}

#[no_mangle]
pub unsafe extern "C" fn eibfs_bottom_up_graph_cut_merging(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MERGE_INPUT_MAX { return -1; }
    let nv = *input; let mv = *input.add(1); let bv = *input.add(2);
    if nv < 2 || nv > MERGE_NMAX as i64 || mv < 0 || mv > MERGE_MMAX as i64 || bv < 1 || bv > 4 || bv > nv || length != 3 + 3 * nv as usize + 4 * mv as usize { return -1; }
    let n = nv as usize; let m = mv as usize; let blocks = bv as usize;
    let mut block = [0usize; 6]; let mut seen = [false; 4];
    let mut source_caps = [0i64; 6]; let mut sink_caps = [0i64; 6];
    for v in 0..n { let id = *input.add(3 + v); if id < 0 || id >= bv { return -1; } block[v] = id as usize; seen[block[v]] = true; }
    for b in 0..blocks { if !seen[b] { return -1; } }
    for v in 0..n { source_caps[v] = *input.add(3 + n + v); sink_caps[v] = *input.add(3 + 2 * n + v); if source_caps[v] < 0 || source_caps[v] > 7 || sink_caps[v] < 0 || sink_caps[v] > 7 { return -1; } }
    let mut edges = [MergeEdge { u: 0, v: 0, uv: 0, vu: 0 }; 6];
    for e in 0..m { let p = 3 + 3 * n + 4 * e; let u = *input.add(p); let v = *input.add(p + 1); let uv = *input.add(p + 2); let vu = *input.add(p + 3); if u < 0 || u >= nv || v < 0 || v >= nv || u == v || uv < 0 || uv > 7 || vu < 0 || vu > 7 { return -1; } edges[e] = MergeEdge { u: u as usize, v: v as usize, uv, vu }; }

    let mut tags = [0usize; 6]; let mut flow = [0i64; 4];
    for b in 0..blocks {
        let mut vertices = [0usize; 6]; let mut active = [false; 6]; let mut k = 0usize;
        for v in 0..n { if block[v] == b { vertices[k] = v; k += 1; active[v] = true; } }
        let mut best_cost = i64::MAX; let mut best_mask = 0usize;
        for mask in 0..(1usize << k) { let mut cost = 0i64;
            for i in 0..k { let v=vertices[i]; cost += if mask & (1usize << i) != 0 { sink_caps[v] } else { source_caps[v] }; }
            for e in 0..m { if block[edges[e].u] == b && block[edges[e].v] == b { let mut iu=0;let mut iv=0;while vertices[iu]!=edges[e].u{iu+=1;}while vertices[iv]!=edges[e].v{iv+=1;}let us=mask&(1usize<<iu)!=0;let vs=mask&(1usize<<iv)!=0;if us&&!vs{cost+=edges[e].uv;}else if vs&&!us{cost+=edges[e].vu;} } }
            if cost < best_cost || (cost == best_cost && mask < best_mask) { best_cost=cost;best_mask=mask; }
        }
        for i in 0..k { tags[vertices[i]] = if best_mask & (1usize << i) != 0 { 1 } else { 2 }; }
        flow[b] = merge_component_flow(n, &active, &source_caps, &sink_caps, &edges, m);
        if flow[b] < 0 { return -1; }
    }
    let mut score = [[0i64; 4]; 4]; let mut has = [[false; 4]; 4];
    for e in 0..m { if block[edges[e].u] != block[edges[e].v] && (edges[e].uv > 0 || edges[e].vu > 0) { let mut a=block[edges[e].u];let mut b=block[edges[e].v];if a>b{std::mem::swap(&mut a,&mut b);}has[a][b]=true;if tags[edges[e].u]!=tags[edges[e].v]{score[a][b]+=(edges[e].uv>0)as i64+(edges[e].vu>0)as i64;} } }
    let mut pair_a=[0usize;6];let mut pair_b=[0usize;6];let mut pair_score=[0i64;6];let mut pair_count=0usize;
    for a in 0..blocks { for b in a+1..blocks { if has[a][b] { let mut pos=pair_count;pair_count+=1;while pos>0&&(pair_score[pos-1]<score[a][b]||(pair_score[pos-1]==score[a][b]&&(pair_a[pos-1]>a||(pair_a[pos-1]==a&&pair_b[pos-1]>b)))){pair_a[pos]=pair_a[pos-1];pair_b[pos]=pair_b[pos-1];pair_score[pos]=pair_score[pos-1];pos-=1;}pair_a[pos]=a;pair_b[pos]=b;pair_score[pos]=score[a][b]; } } }
    let mut parent=[0usize,1,2,3];
    for i in 0..pair_count { let a=merge_find(&mut parent,pair_a[i]);let b=merge_find(&mut parent,pair_b[i]);if a==b{continue;}let root=a.min(b);let other=a.max(b);parent[other]=root;let mut active=[false;6];for v in 0..n{active[v]=merge_find(&mut parent,block[v])==root;}flow[root]=merge_component_flow(n,&active,&source_caps,&sink_caps,&edges,m);if flow[root]<0{return -1;}flow[other]=0; }
    let mut answer=0i64;for b in 0..blocks{if merge_find(&mut parent,b)==b{answer+=flow[b];}}answer
}
