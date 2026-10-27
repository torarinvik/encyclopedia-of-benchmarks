const N: usize = 8;
const MAX_M: usize = 28;
const MAX_OUT: usize = 1 + 2 * N + N * N;

fn ancestor(parent: &[[i32; N]; N], source: usize, a: usize, target: usize) -> bool {
    let mut v = target as i32;
    while v >= 0 {
        if v as usize == a { return true; }
        if v as usize == source { break; }
        v = parent[source][v as usize];
    }
    false
}
unsafe fn put_i64(out: *mut u8, pos: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *out.add(pos + b) = (bits >> (8 * b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn hub_labeling_greedy_order(input: *const i64, length: usize,
                                                    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_M { return -1; }
    let n0 = *input; let m0 = *input.add(1);
    if n0 < 1 || n0 > N as i64 || m0 < 0 || m0 > n0 * (n0 - 1) / 2 || length != 2 + 2 * m0 as usize { return -1; }
    let n = n0 as usize; let m = m0 as usize;
    let mut adj = [[false; N]; N];
    let mut prev = (-1i64, -1i64);
    for e in 0..m {
        let u = *input.add(2 + 2 * e); let v = *input.add(3 + 2 * e);
        if u < 0 || v <= u || v >= n0 || (e > 0 && (u, v) <= prev) { return -1; }
        adj[u as usize][v as usize] = true; adj[v as usize][u as usize] = true; prev = (u, v);
    }
    let mut parent = [[-1i32; N]; N]; let mut depth = [[-1i32; N]; N]; let mut ways = [[0u8; N]; N];
    for s in 0..n {
        let mut queue = [0usize; N]; let mut head = 0usize; let mut tail = 0usize;
        queue[tail] = s; tail += 1; depth[s][s] = 0; ways[s][s] = 1;
        while head < tail {
            let u = queue[head]; head += 1;
            for v in 0..n {
                if !adj[u][v] { continue; }
                if depth[s][v] < 0 {
                    depth[s][v] = depth[s][u] + 1; parent[s][v] = u as i32; ways[s][v] = ways[s][u];
                    queue[tail] = v; tail += 1;
                } else if depth[s][v] == depth[s][u] + 1 {
                    ways[s][v] = core::cmp::min(2, ways[s][v] + ways[s][u]);
                }
            }
        }
        for v in 0..n { if depth[s][v] < 0 || ways[s][v] != 1 { return -1; } }
    }
    let mut active = [[true; N]; N]; let mut order = [0usize; N]; let mut rank = [0usize; N];
    for turn in 0..n {
        let mut counts = [0usize; N];
        for s in 0..n { for t in 0..n { if active[s][t] {
            let mut v = t as i32;
            while v >= 0 { counts[v as usize] += 1; if v as usize == s { break; } v = parent[s][v as usize]; }
        } } }
        let mut best = 0usize;
        for v in 1..n { if counts[v] > counts[best] { best = v; } }
        order[turn] = best; rank[best] = turn;
        for s in 0..n { for t in 0..n { if active[s][t] && ancestor(&parent, s, best, t) { active[s][t] = false; } } }
    }
    let mut has = [[false; N]; N]; let mut label_dist = [[0i32; N]; N];
    for u in 0..n { for v in u..n {
        let mut path = [0usize; N]; let mut path_len = 0usize; let mut x = v as i32;
        while x >= 0 { path[path_len] = x as usize; path_len += 1; if x as usize == u { break; } x = parent[u][x as usize]; }
        if x < 0 { return -1; }
        let mut hub = path[0];
        for i in 1..path_len { if rank[path[i]] < rank[hub] { hub = path[i]; } }
        has[u][hub] = true; has[v][hub] = true; label_dist[u][hub] = depth[u][hub]; label_dist[v][hub] = depth[v][hub];
    } }
    let mut staged = [0i64; MAX_OUT]; let mut used = 0usize;
    staged[used] = n as i64; used += 1;
    for i in 0..n { staged[used] = order[i] as i64; used += 1; }
    for v in 0..n {
        let mut count = 0i64; for h in 0..n { if has[v][h] { count += 1; } }
        staged[used] = count; used += 1;
        for h in 0..n { if has[v][h] { staged[used] = (h as i64) | ((label_dist[v][h] as i64) << 8); used += 1; } }
    }
    let required = used * 8;
    if output.is_null() || capacity < required { return -2; }
    for i in 0..used { put_i64(output, i * 8, staged[i]); }
    required as i64
}
