const MIN_N: usize = 3;
const MAX_N: usize = 8;
const MAX_M: usize = 12;
const MAX_LEN: usize = 39;
const MAX_CANDIDATES: usize = 96;

#[derive(Clone, Copy, Default)]
struct Edge { u: usize, v: usize, weight: i64 }

fn cycle_weight(mask: u64, edges: &[Edge; MAX_M], m: usize) -> i64 {
    let mut total = 0;
    for e in 0..m { if (mask >> e) & 1 != 0 { total += edges[e].weight; } }
    total
}

fn horton_weight(n: usize, m: usize, edges: &[Edge; MAX_M]) -> i64 {
    let mut candidates = [0_u64; MAX_CANDIDATES];
    let mut costs = [0_i64; MAX_CANDIDATES];
    let mut candidate_count = 0;
    for root in 0..n {
        let mut distance = [i64::MAX; MAX_N];
        let mut parent = [-1_i32; MAX_N];
        let mut parent_edge = [-1_i32; MAX_N];
        let mut settled = [false; MAX_N];
        let mut tree_edge = [false; MAX_M];
        let mut path_mask = [0_u64; MAX_N];
        distance[root] = 0;
        let tie_scale = (m as i64 + 1) * (1_i64 << m);
        for _ in 0..n {
            let mut vertex: Option<usize> = None;
            for v in 0..n {
                if !settled[v] && distance[v] != i64::MAX &&
                    vertex.map_or(true, |old| distance[v] < distance[old] || (distance[v] == distance[old] && v < old)) {
                    vertex = Some(v);
                }
            }
            let Some(u) = vertex else { break; };
            settled[u] = true;
            for e in 0..m {
                let edge = edges[e];
                let v = if edge.u == u { edge.v } else if edge.v == u { edge.u } else { continue };
                if settled[v] { continue; }
                let candidate = distance[u] + edge.weight * tie_scale + (1_i64 << e);
                if candidate < distance[v] {
                    distance[v] = candidate;
                    parent[v] = u as i32;
                    parent_edge[v] = e as i32;
                }
            }
        }
        for v in 0..n {
            if v == root { continue; }
            let mut cursor = v;
            let mut steps = 0;
            while cursor != root && steps < n {
                let pe = parent_edge[cursor];
                if pe < 0 { return -1; }
                tree_edge[pe as usize] = true;
                path_mask[v] |= 1_u64 << (pe as u32);
                cursor = parent[cursor] as usize;
                steps += 1;
            }
            if cursor != root { return -1; }
        }
        for e in 0..m {
            if tree_edge[e] { continue; }
            let edge = edges[e];
            let cycle = path_mask[edge.u] ^ path_mask[edge.v] ^ (1_u64 << e);
            if cycle == 0 { continue; }
            if candidates[..candidate_count].contains(&cycle) { continue; }
            if candidate_count < MAX_CANDIDATES {
                candidates[candidate_count] = cycle;
                costs[candidate_count] = cycle_weight(cycle, edges, m);
                candidate_count += 1;
            }
        }
    }
    for i in 0..candidate_count { for j in i + 1..candidate_count {
        if costs[j] < costs[i] || (costs[j] == costs[i] && candidates[j] < candidates[i]) {
            costs.swap(i, j); candidates.swap(i, j);
        }
    }}
    let dimension = m as i32 - n as i32 + 1;
    let mut basis = [0_u64; MAX_M];
    let mut rank = 0_i32;
    let mut total = 0_i64;
    for i in 0..candidate_count {
        if rank == dimension { break; }
        let mut residual = candidates[i];
        for bit in (0..m).rev() {
            if (residual >> bit) & 1 == 0 { continue; }
            if basis[bit] != 0 { residual ^= basis[bit]; }
            else { basis[bit] = residual; rank += 1; total += costs[i]; break; }
        }
    }
    if rank == dimension { total } else { -1 }
}

#[no_mangle]
pub unsafe extern "C" fn minimum_cycle_basis_horton(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LEN { return -1; }
    if *input < MIN_N as i64 || *input > MAX_N as i64 { return -1; }
    let n = *input as usize;
    let m_value = *input.add(1);
    if m_value < n as i64 - 1 || m_value > MAX_M as i64 || m_value > (n * (n - 1) / 2) as i64 { return -1; }
    let m = m_value as usize;
    if length != 2 + 3 * m { return -1; }
    let mut edges = [Edge::default(); MAX_M];
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut previous = None;
    for e in 0..m {
        let u_value = *input.add(2 + 3 * e);
        let v_value = *input.add(3 + 3 * e);
        let weight = *input.add(4 + 3 * e);
        if u_value < 0 || v_value < 0 || u_value >= n as i64 || v_value >= n as i64 || u_value >= v_value || !(1..=9).contains(&weight) { return -1; }
        let (u, v) = (u_value as usize, v_value as usize);
        if previous.map_or(false, |old: (usize, usize)| (u, v) <= old) { return -1; }
        previous = Some((u, v));
        edges[e] = Edge { u, v, weight };
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    let mut seen = [false; MAX_N];
    let mut queue = [0_usize; MAX_N];
    let (mut head, mut tail) = (0, 1);
    seen[0] = true;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..n { if adjacent[u][v] && !seen[v] { seen[v] = true; queue[tail] = v; tail += 1; } }
    }
    if (0..n).any(|v| !seen[v]) { return -1; }
    horton_weight(n, m, &edges)
}
