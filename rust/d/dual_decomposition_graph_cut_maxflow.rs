const MAX_N: usize = 6;
const MAX_M: usize = 10;
const STRIDE: usize = 8;
const OFFSET: i64 = 7000;
const SCALES: [i64; 9] = [0, 2, 2, 6, 12, 60, 60, 420, 840];

fn member(owner: i64, side: i64) -> bool { owner == side || owner == 2 }

fn solve(side: i64, n: usize, m: usize, owner: &[i64; MAX_N],
         source_cap: &[i64; MAX_N], sink_cap: &[i64; MAX_N],
         eu: &[usize; MAX_M], ev: &[usize; MAX_M],
         uv: &[i64; MAX_M], vu: &[i64; MAX_M],
         lambda: &[i64; MAX_N], scale: i64) -> (i64, [i64; MAX_N]) {
    let source = n; let sink = n + 1; let size = n + 2;
    let mut residual = [[0i64; STRIDE]; STRIDE];
    let (mut constant, mut flow, mut source_sum, mut lambda_sum) = (0i64, 0i64, 0i64, 0i64);
    for u in 0..n {
        if member(owner[u], side) {
            let factor = if owner[u] == 2 { scale / 2 } else { scale };
            residual[source][u] += source_cap[u] * factor;
            residual[u][sink] += sink_cap[u] * factor;
        }
        source_sum += source_cap[u];
        if owner[u] == 2 { lambda_sum += lambda[u].abs(); }
    }
    for i in 0..m {
        if member(owner[eu[i]], side) && member(owner[ev[i]], side) {
            let factor = if owner[eu[i]] == 2 && owner[ev[i]] == 2 { scale / 2 } else { scale };
            residual[eu[i]][ev[i]] += uv[i] * factor;
            residual[ev[i]][eu[i]] += vu[i] * factor;
        }
    }
    for u in 0..n {
        if owner[u] == 2 {
            let q = if side == 0 { lambda[u] } else { -lambda[u] };
            if q >= 0 { residual[source][u] += q; }
            else { residual[u][sink] += -q; constant += q; }
        }
    }
    loop {
        let mut parent = [usize::MAX; STRIDE];
        let mut queue = [0usize; STRIDE];
        parent[source] = source;
        let (mut head, mut tail) = (0usize, 0usize);
        queue[tail] = source; tail += 1;
        while head < tail && parent[sink] == usize::MAX {
            let u = queue[head]; head += 1;
            for v in 0..size {
                if parent[v] == usize::MAX && residual[u][v] > 0 {
                    parent[v] = u; queue[tail] = v; tail += 1;
                    if v == sink { break; }
                }
            }
        }
        if parent[sink] == usize::MAX {
            let mut labels = [0i64; MAX_N];
            for u in 0..n { labels[u] = if member(owner[u], side) && parent[u] == usize::MAX { 1 } else { 0 }; }
            return (flow + constant, labels);
        }
        let mut amount = source_sum * scale + lambda_sum + 1;
        let mut v = sink;
        while v != source { let u = parent[v]; amount = amount.min(residual[u][v]); v = u; }
        v = sink;
        while v != source { let u = parent[v]; residual[u][v] -= amount; residual[v][u] += amount; v = u; }
        flow += amount;
    }
}

#[no_mangle]
pub unsafe extern "C" fn dual_decomposition_graph_cut_maxflow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 63 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let (rn, rm, ro, rt) = (words[0], words[1], words[2], words[3]);
    if rn < 3 || rn > MAX_N as i64 || rm < 0 || rm > MAX_M as i64 || ro < 1 || ro > 3 || rt < 1 || rt > 8 ||
        length != 4 + 3 * rn as usize + 4 * rm as usize { return -1; }
    let (n, m, overlap, rounds) = (rn as usize, rm as usize, ro as usize, rt as usize);
    let mut at = 4usize;
    let mut owner = [0i64; MAX_N]; let mut counts = [0usize; 3];
    for u in 0..n {
        let x = words[at]; at += 1;
        if !(0..=2).contains(&x) { return -1; }
        owner[u] = x; counts[x as usize] += 1;
    }
    if counts[0] == 0 || counts[1] == 0 || counts[2] != overlap { return -1; }
    let mut source_cap = [0i64; MAX_N]; let mut sink_cap = [0i64; MAX_N];
    for u in 0..n {
        let value = words[at]; at += 1;
        if !(0..=6).contains(&value) || value % 2 != 0 { return -1; }
        source_cap[u] = value;
    }
    for u in 0..n {
        let value = words[at]; at += 1;
        if !(0..=6).contains(&value) || value % 2 != 0 { return -1; }
        sink_cap[u] = value;
    }
    let mut eu = [0usize; MAX_M]; let mut ev = [0usize; MAX_M];
    let mut uv = [0i64; MAX_M]; let mut vu = [0i64; MAX_M];
    for i in 0..m {
        let (ru, rv, c, d) = (words[at], words[at + 1], words[at + 2], words[at + 3]); at += 4;
        if ru < 0 || ru >= rn || rv < 0 || rv >= rn || ru == rv ||
            (owner[ru as usize] == 0 && owner[rv as usize] == 1) || (owner[ru as usize] == 1 && owner[rv as usize] == 0) ||
            !(0..=6).contains(&c) || c % 2 != 0 || !(0..=6).contains(&d) || d % 2 != 0 { return -1; }
        eu[i] = ru as usize; ev[i] = rv as usize; uv[i] = c; vu[i] = d;
    }
    let scale = SCALES[rounds];
    let mut lambda = [0i64; MAX_N];
    let (mut dual_scaled, mut agreement) = (0i64, false);
    for iteration in 1..=rounds {
        let (energy_m, labels_m) = solve(0,n,m,&owner,&source_cap,&sink_cap,&eu,&ev,&uv,&vu,&lambda,scale);
        let (energy_n, labels_n) = solve(1,n,m,&owner,&source_cap,&sink_cap,&eu,&ev,&uv,&vu,&lambda,scale);
        dual_scaled = energy_m + energy_n;
        agreement = (0..n).all(|u| owner[u] != 2 || labels_m[u] == labels_n[u]);
        if agreement || iteration == rounds { break; }
        let step = scale / iteration as i64;
        for u in 0..n { if owner[u] == 2 { lambda[u] += step * (labels_m[u] - labels_n[u]); } }
    }
    2 * (dual_scaled + OFFSET) + if agreement { 1 } else { 0 }
}
