const MAX_N: usize = 8;
const MAX_M: usize = 16;
const MAX_B: usize = 4;
const STRIDE: usize = 10;

fn allowed_arc(u: usize, v: usize, n: usize, allowed: &[bool; MAX_N]) -> bool {
    if u < n && !allowed[u] { return false; }
    if v < n && !allowed[v] { return false; }
    v != n && u != n + 1
}

fn augment(residual: &mut [[i64; STRIDE]; STRIDE], n: usize, allowed: &[bool; MAX_N]) {
    let source = n;
    let sink = n + 1;
    loop {
        let mut parent = [usize::MAX; STRIDE];
        let mut queue = [0usize; STRIDE];
        parent[source] = source;
        let (mut head, mut tail) = (0usize, 0usize);
        queue[tail] = source; tail += 1;
        while head < tail && parent[sink] == usize::MAX {
            let u = queue[head]; head += 1;
            for v in 0..n + 2 {
                if parent[v] == usize::MAX && residual[u][v] > 0 && allowed_arc(u, v, n, allowed) {
                    parent[v] = u; queue[tail] = v; tail += 1;
                    if v == sink { break; }
                }
            }
        }
        if parent[sink] == usize::MAX { return; }
        let mut amount = (n as i64) * 7;
        let mut v = sink;
        while v != source { let u = parent[v]; amount = amount.min(residual[u][v]); v = u; }
        v = sink;
        while v != source { let u = parent[v]; residual[u][v] -= amount; residual[v][u] += amount; v = u; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn adaptive_bottom_up_graph_cut_merging(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 92 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let (rn, rm, rb) = (words[0], words[1], words[2]);
    if !(2..=MAX_N as i64).contains(&rn) || !(0..=MAX_M as i64).contains(&rm)
        || !(1..=MAX_B as i64).contains(&rb) || rb > rn
        || length != 3 + 3 * rn as usize + 4 * rm as usize { return -1; }
    let (n, m, bcount) = (rn as usize, rm as usize, rb as usize);
    let mut at = 3usize;
    let mut block = [0usize; MAX_N];
    let mut seen = [false; MAX_B];
    for u in 0..n {
        let x = words[at]; at += 1;
        if x < 0 || x >= rb { return -1; }
        block[u] = x as usize; seen[block[u]] = true;
    }
    if seen[..bcount].iter().any(|x| !x) { return -1; }
    let mut source_cap = [0i64; MAX_N];
    let mut sink_cap = [0i64; MAX_N];
    for c in &mut source_cap[..n] { *c = words[at]; at += 1; if !(0..=7).contains(c) { return -1; } }
    for c in &mut sink_cap[..n] { *c = words[at]; at += 1; if !(0..=7).contains(c) { return -1; } }

    let mut eu = [0usize; MAX_M]; let mut ev = [0usize; MAX_M];
    let mut uv = [0i64; MAX_M]; let mut vu = [0i64; MAX_M];
    let mut ba = [0usize; MAX_M]; let mut bb = [0usize; MAX_M];
    let mut cross = [false; MAX_M]; let mut enabled = [false; MAX_M];
    let mut residual = [[0i64; STRIDE]; STRIDE];
    for u in 0..n { residual[n][u] += source_cap[u]; residual[u][n + 1] += sink_cap[u]; }
    let mut potential = [[0i64; MAX_B]; MAX_B];
    let mut present = [[false; MAX_B]; MAX_B];
    for i in 0..m {
        let (ru, rv, c, d) = (words[at], words[at + 1], words[at + 2], words[at + 3]); at += 4;
        if ru < 0 || ru >= rn || rv < 0 || rv >= rn || ru == rv || !(0..=7).contains(&c) || !(0..=7).contains(&d) { return -1; }
        let (u, v) = (ru as usize, rv as usize);
        eu[i] = u; ev[i] = v; uv[i] = c; vu[i] = d;
        if block[u] == block[v] { residual[u][v] += c; residual[v][u] += d; }
        else {
            ba[i] = block[u].min(block[v]); bb[i] = block[u].max(block[v]);
            cross[i] = c != 0 || d != 0;
            if cross[i] { present[ba[i]][bb[i]] = true; }
        }
    }
    let mut allowed = [false; MAX_N];
    for b in 0..bcount {
        for u in 0..n { allowed[u] = block[u] == b; }
        augment(&mut residual, n, &allowed);
    }
    let mut tag = [0i32; MAX_N];
    for b in 0..bcount {
        for u in 0..n { allowed[u] = block[u] == b; }
        let mut ss = [false; STRIDE]; let mut tt = [false; STRIDE];
        let mut queue = [0usize; STRIDE];
        let (mut head, mut tail) = (0usize, 0usize); ss[n] = true; queue[tail] = n; tail += 1;
        while head < tail { let u = queue[head]; head += 1; for v in 0..n + 2 {
            if !ss[v] && residual[u][v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v]) { ss[v] = true; queue[tail] = v; tail += 1; }
        }}
        head = 0; tail = 0; tt[n + 1] = true; queue[tail] = n + 1; tail += 1;
        while head < tail { let v = queue[head]; head += 1; for u in 0..n + 2 {
            if !tt[u] && residual[u][v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v]) { tt[u] = true; queue[tail] = u; tail += 1; }
        }}
        for u in 0..n { if allowed[u] { tag[u] = if ss[u] { 1 } else if tt[u] { 2 } else { 0 }; } }
    }
    for i in 0..m { if cross[i] && tag[eu[i]] != tag[ev[i]] { potential[ba[i]][bb[i]] += (if uv[i] > 0 { 1 } else { 0 }) + (if vu[i] > 0 { 1 } else { 0 }); } }

    let mut order = [(0usize, 0usize); MAX_B * MAX_B]; let mut order_n = 0usize;
    for a in 0..bcount { for b in a + 1..bcount { if present[a][b] {
        let mut p = order_n; order_n += 1;
        while p > 0 {
            let prev = order[p - 1];
            if potential[prev.0][prev.1] > potential[a][b]
                || (potential[prev.0][prev.1] == potential[a][b] && prev <= (a, b)) { break; }
            order[p] = prev; p -= 1;
        }
        order[p] = (a, b);
    }}}
    let mut parent = [0usize, 1, 2, 3];
    for &(a0, b0) in &order[..order_n] {
        let (mut a, mut b) = (a0, b0);
        while parent[a] != a { a = parent[a]; }
        while parent[b] != b { b = parent[b]; }
        if a == b { continue; }
        let root = a.min(b); let other = a.max(b); parent[other] = root;
        for i in 0..m { if cross[i] && !enabled[i] {
            let (mut x, mut y) = (ba[i], bb[i]);
            while parent[x] != x { x = parent[x]; }
            while parent[y] != y { y = parent[y]; }
            if x == y { residual[eu[i]][ev[i]] += uv[i]; residual[ev[i]][eu[i]] += vu[i]; enabled[i] = true; }
        }}
        for u in 0..n { let mut x = block[u]; while parent[x] != x { x = parent[x]; } allowed[u] = x == root; }
        augment(&mut residual, n, &allowed);
    }
    (0..n).map(|u| source_cap[u] - residual[n][u]).sum()
}
