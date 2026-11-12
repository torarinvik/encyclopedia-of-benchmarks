use std::slice;

const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 90;

fn edge_before(a: usize, b: usize, u: &[i64; MAX_M], v: &[i64; MAX_M], w: &[i64; MAX_M]) -> bool {
    (w[a], u[a], v[a]) < (w[b], u[b], v[b])
}

#[no_mangle]
pub unsafe extern "C" fn baswana_sen_weighted_spanner(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let (n64, m64, k) = (values[0], values[1], values[2]);
    if !(2..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64) || !(2..=3).contains(&k) { return -1; }
    let (n, m, rounds) = (n64 as usize, m64 as usize, (k - 1) as usize);
    if length != 3 + rounds + 3 * m { return -1; }
    let mut masks = [0i64; MAX_N];
    for r in 0..rounds {
        masks[r] = values[3 + r];
        if masks[r] < 0 || masks[r] >= (1i64 << n) { return -1; }
    }
    let mut edge_u = [0i64; MAX_M];
    let mut edge_v = [0i64; MAX_M];
    let mut edge_w = [0i64; MAX_M];
    let mut active = [false; MAX_M];
    let mut selected = [false; MAX_M];
    let offset = 3 + rounds;
    for e in 0..m {
        edge_u[e] = values[offset + 3 * e];
        edge_v[e] = values[offset + 3 * e + 1];
        edge_w[e] = values[offset + 3 * e + 2];
        if edge_u[e] < 0 || edge_v[e] <= edge_u[e] || edge_v[e] >= n64 || !(1..=32).contains(&edge_w[e]) { return -1; }
        if (0..e).any(|p| edge_u[p] == edge_u[e] && edge_v[p] == edge_v[e]) { return -1; }
        active[e] = true;
    }
    if output.is_null() || capacity < m { return -2; }

    let mut cluster = [0i32; MAX_N];
    let mut next_cluster = [-1i32; MAX_N];
    for v in 0..n { cluster[v] = v as i32; }
    for r in 0..rounds {
        let mut sampled = [false; MAX_N];
        let mut remove = [false; MAX_M];
        let mut group_best = [[m; MAX_N]; MAX_N];
        next_cluster.fill(-1);
        for v in 0..n {
            let center = cluster[v];
            if center >= 0 && (masks[r] & (1i64 << center)) != 0 { sampled[center as usize] = true; }
        }
        for v in 0..n {
            let center = cluster[v];
            if center >= 0 && sampled[center as usize] { next_cluster[v] = center; }
        }
        for e in 0..m {
            if !active[e] { continue; }
            let (u, v) = (edge_u[e] as usize, edge_v[e] as usize);
            if cluster[v] >= 0 {
                let c = cluster[v] as usize;
                if group_best[u][c] == m || edge_before(e, group_best[u][c], &edge_u, &edge_v, &edge_w) { group_best[u][c] = e; }
            }
            if cluster[u] >= 0 {
                let c = cluster[u] as usize;
                if group_best[v][c] == m || edge_before(e, group_best[v][c], &edge_u, &edge_v, &edge_w) { group_best[v][c] = e; }
            }
        }
        for v in 0..n {
            let old = cluster[v];
            if old < 0 || sampled[old as usize] { continue; }
            let mut best = m;
            for c in 0..n {
                let candidate = group_best[v][c];
                if sampled[c] && candidate != m && (best == m || edge_before(candidate, best, &edge_u, &edge_v, &edge_w)) { best = candidate; }
            }
            if best == m {
                for c in 0..n {
                    let least = group_best[v][c];
                    if least == m { continue; }
                    selected[least] = true;
                    for e in 0..m {
                        if !active[e] { continue; }
                        let (a, b) = (edge_u[e] as usize, edge_v[e] as usize);
                        if (a == v && cluster[b] == c as i32) || (b == v && cluster[a] == c as i32) { remove[e] = true; }
                    }
                }
                continue;
            }
            let (a, b) = (edge_u[best] as usize, edge_v[best] as usize);
            let landing = cluster[if a == v { b } else { a }];
            next_cluster[v] = landing;
            selected[best] = true;
            for c in 0..n {
                let least = group_best[v][c];
                if least == m { continue; }
                let erase_group = c as i32 == landing || edge_w[least] < edge_w[best];
                if c as i32 != landing && edge_w[least] < edge_w[best] { selected[least] = true; }
                if erase_group {
                    for e in 0..m {
                        if !active[e] { continue; }
                        let (x, y) = (edge_u[e] as usize, edge_v[e] as usize);
                        if (x == v && cluster[y] == c as i32) || (y == v && cluster[x] == c as i32) { remove[e] = true; }
                    }
                }
            }
        }
        for e in 0..m { if remove[e] { active[e] = false; } }
        for e in 0..m {
            if active[e] {
                let (u, v) = (edge_u[e] as usize, edge_v[e] as usize);
                if next_cluster[u] >= 0 && next_cluster[u] == next_cluster[v] { active[e] = false; }
            }
        }
        cluster = next_cluster;
    }
    let mut group_best = [[m; MAX_N]; MAX_N];
    for e in 0..m {
        if !active[e] { continue; }
        let (u, v) = (edge_u[e] as usize, edge_v[e] as usize);
        if cluster[v] >= 0 {
            let c = cluster[v] as usize;
            if group_best[u][c] == m || edge_before(e, group_best[u][c], &edge_u, &edge_v, &edge_w) { group_best[u][c] = e; }
        }
        if cluster[u] >= 0 {
            let c = cluster[u] as usize;
            if group_best[v][c] == m || edge_before(e, group_best[v][c], &edge_u, &edge_v, &edge_w) { group_best[v][c] = e; }
        }
    }
    for v in 0..n { if cluster[v] >= 0 { for c in 0..n { if group_best[v][c] != m { selected[group_best[v][c]] = true; } } } }
    for e in 0..m { *output.add(e) = u8::from(selected[e]); }
    m as i64
}
