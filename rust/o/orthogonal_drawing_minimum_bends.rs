use std::slice;

const NMAX: usize = 8;
const MMAX: usize = 16;
const FMAX: usize = 10;
const INPUT_MAX: usize = 79;
const NODE_MAX: usize = NMAX + FMAX + 2;
const EDGE_MAX: usize = 200;
const INF: i64 = 1_i64 << 60;

#[derive(Clone, Copy, Default)]
struct Edge { from: usize, to: usize, reverse: usize, cap: i64, cost: i64 }

fn connected(adj: &[[bool; NMAX]; NMAX], n: usize, removed: isize) -> bool {
    let start = if removed == 0 { 1 } else { 0 };
    let mut seen = [false; NMAX];
    let mut stack = [0_usize; NMAX];
    let (mut top, mut count) = (0, 0);
    seen[start] = true; stack[top] = start; top += 1;
    while top > 0 {
        top -= 1;
        let u = stack[top]; count += 1;
        for v in 0..n {
            if v as isize != removed && adj[u][v] && !seen[v] {
                seen[v] = true; stack[top] = v; top += 1;
            }
        }
    }
    count == n - (if removed >= 0 { 1 } else { 0 })
}

fn add_edge(edges: &mut [Edge; EDGE_MAX], count: &mut usize,
            u: usize, v: usize, cap: i64, cost: i64) -> bool {
    if *count + 2 > EDGE_MAX { return false; }
    let e = *count;
    edges[e] = Edge { from: u, to: v, reverse: e + 1, cap, cost };
    edges[e + 1] = Edge { from: v, to: u, reverse: e, cap: 0, cost: -cost };
    *count += 2;
    true
}

fn compute(values: &[i64]) -> Option<i64> {
    if values.len() < 4 || values.len() > INPUT_MAX { return None; }
    let (n0, m0, f0, outer0) = (values[0], values[1], values[2], values[3]);
    if !(3..=8).contains(&n0) || m0 < n0 || m0 > 16 || !(2..=10).contains(&f0)
        || f0 != m0 - n0 + 2 || outer0 < 0 || outer0 >= f0 { return None; }
    let (n, m, f, outer) = (n0 as usize, m0 as usize, f0 as usize, outer0 as usize);
    let mut adj = [[false; NMAX]; NMAX];
    let mut degree = [0_usize; NMAX];
    let mut edge_u = [0_usize; MMAX];
    let mut edge_v = [0_usize; MMAX];
    let mut uses = [[0_usize; NMAX]; NMAX];
    let mut p = 4;
    for e in 0..m {
        if p + 2 > values.len() { return None; }
        let (u0, v0) = (values[p], values[p + 1]); p += 2;
        if u0 < 0 || v0 <= u0 || v0 >= n0 { return None; }
        let (u, v) = (u0 as usize, v0 as usize);
        if adj[u][v] || (e > 0 && (u < edge_u[e - 1] || (u == edge_u[e - 1] && v <= edge_v[e - 1]))) { return None; }
        adj[u][v] = true; adj[v][u] = true;
        degree[u] += 1; degree[v] += 1; edge_u[e] = u; edge_v[e] = v;
    }
    if degree[..n].iter().any(|&d| !(2..=4).contains(&d)) { return None; }
    let mut faces = [[0_usize; NMAX]; FMAX];
    let mut widths = [0_usize; FMAX];
    let mut link_adj = [[[false; NMAX]; NMAX]; NMAX];
    let mut link_degree = [[0_usize; NMAX]; NMAX];
    for face in 0..f {
        if p >= values.len() { return None; }
        let width0 = values[p]; p += 1;
        if width0 < 3 || width0 > n0 || p + width0 as usize > values.len() { return None; }
        let width = width0 as usize; widths[face] = width;
        let mut row_seen = [false; NMAX];
        for i in 0..width {
            let x0 = values[p]; p += 1;
            if x0 < 0 || x0 >= n0 || row_seen[x0 as usize] { return None; }
            let x = x0 as usize; row_seen[x] = true; faces[face][i] = x;
        }
        for i in 0..width {
            let u = faces[face][i]; let v = faces[face][(i + 1) % width];
            if !adj[u][v] { return None; }
            uses[u][v] += 1;
        }
        for i in 0..width {
            let center = faces[face][i];
            let before = faces[face][(i + width - 1) % width];
            let after = faces[face][(i + 1) % width];
            if before == after { return None; }
            link_adj[center][before][after] = true;
            link_adj[center][after][before] = true;
            link_degree[center][before] += 1;
            link_degree[center][after] += 1;
        }
    }
    if p != values.len() || n as i64 - m0 + f0 != 2 || !connected(&adj, n, -1) { return None; }
    for v in 0..n { if !connected(&adj, n, v as isize) { return None; } }
    for e in 0..m { if uses[edge_u[e]][edge_v[e]] != 1 || uses[edge_v[e]][edge_u[e]] != 1 { return None; } }
    for center in 0..n {
        let mut start = None;
        let mut incident_count = 0;
        for neighbor in 0..n {
            if adj[center][neighbor] {
                if link_degree[center][neighbor] != 2 { return None; }
                if start.is_none() { start = Some(neighbor); }
                incident_count += 1;
            } else if link_degree[center][neighbor] != 0 { return None; }
        }
        let seed = start?;
        let mut reached = [false; NMAX];
        let mut stack = [0_usize; NMAX];
        let (mut top, mut count) = (1, 0);
        reached[seed] = true; stack[0] = seed;
        while top > 0 {
            top -= 1;
            let neighbor = stack[top]; count += 1;
            for other in 0..n {
                if link_adj[center][neighbor][other] && !reached[other] {
                    reached[other] = true; stack[top] = other; top += 1;
                }
            }
        }
        if count != incident_count { return None; }
    }
    let mut face_a = [0_usize; MMAX]; let mut face_b = [0_usize; MMAX]; let mut face_use = [0_usize; MMAX];
    for face in 0..f {
        for i in 0..widths[face] {
            let u = faces[face][i]; let v = faces[face][(i + 1) % widths[face]];
            let (lo, hi) = if u < v { (u, v) } else { (v, u) };
            let e = (0..m).find(|&j| edge_u[j] == lo && edge_v[j] == hi)?;
            if face_use[e] >= 2 { return None; }
            if face_use[e] == 0 { face_a[e] = face; } else { face_b[e] = face; }
            face_use[e] += 1;
        }
    }
    if (0..m).any(|e| face_use[e] != 2 || face_a[e] == face_b[e]) { return None; }

    let base = n + f; let source = base; let sink = base + 1; let node_count = base + 2;
    let mut edges = [Edge::default(); EDGE_MAX]; let mut edge_count = 0;
    let mut balance = [0_i64; NMAX + FMAX];
    for v in 0..n { balance[v] = 4; }
    for face in 0..f {
        let d = widths[face] as i64;
        balance[n + face] -= 2 * d + if face == outer { 4 } else { -4 };
        for i in 0..widths[face] {
            let v = faces[face][i]; balance[v] -= 1; balance[n + face] += 1;
            if !add_edge(&mut edges, &mut edge_count, v, n + face, 4 * n as i64, 0) { return None; }
        }
    }
    for e in 0..m {
        if !add_edge(&mut edges, &mut edge_count, n + face_a[e], n + face_b[e], 4 * n as i64, 1)
            || !add_edge(&mut edges, &mut edge_count, n + face_b[e], n + face_a[e], 4 * n as i64, 1) { return None; }
    }
    let mut need = 0_i64;
    for v in 0..base {
        if balance[v] > 0 {
            if !add_edge(&mut edges, &mut edge_count, source, v, balance[v], 0) { return None; }
            need += balance[v];
        } else if balance[v] < 0 && !add_edge(&mut edges, &mut edge_count, v, sink, -balance[v], 0) { return None; }
    }
    let mut potential = [0_i64; NODE_MAX]; let (mut flow, mut total_cost) = (0_i64, 0_i64);
    while flow < need {
        let mut dist = [INF; NODE_MAX]; let mut parent = [-1_i32; NODE_MAX]; let mut used = [false; NODE_MAX];
        dist[source] = 0;
        for _ in 0..node_count {
            let mut chosen = None;
            for v in 0..node_count {
                if !used[v] && dist[v] != INF && chosen.map_or(true, |u| dist[v] < dist[u]) { chosen = Some(v); }
            }
            let Some(u) = chosen else { break; };
            used[u] = true;
            for e in 0..edge_count {
                if edges[e].from != u || edges[e].cap <= 0 { continue; }
                let v = edges[e].to;
                let candidate = dist[u] + edges[e].cost + potential[u] - potential[v];
                if !used[v] && candidate < dist[v] { dist[v] = candidate; parent[v] = e as i32; }
            }
        }
        if dist[sink] == INF { return None; }
        for v in 0..node_count { if dist[v] != INF { potential[v] += dist[v]; } }
        let mut amount = need - flow; let mut path_cost = 0_i64; let mut v = sink;
        while v != source {
            let e = parent[v]; if e < 0 { return None; }
            let i = e as usize; amount = amount.min(edges[i].cap); path_cost += edges[i].cost; v = edges[i].from;
        }
        v = sink;
        while v != source {
            let e = parent[v] as usize; let from = edges[e].from; let reverse = edges[e].reverse;
            edges[e].cap -= amount; edges[reverse].cap += amount; v = from;
        }
        flow += amount; total_cost += amount * path_cost;
    }
    Some(total_cost)
}

#[no_mangle]
pub unsafe extern "C" fn orthogonal_drawing_minimum_bends(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > INPUT_MAX { return -1; }
    let values = slice::from_raw_parts(input, length);
    let Some(result) = compute(values) else { return -1; };
    if output.is_null() || capacity < 8 { return -2; }
    slice::from_raw_parts_mut(output, 8).copy_from_slice(&result.to_le_bytes());
    8
}
