// Clean-room bounded SAGA-Bench incremental analytics profile; see package LICENSE.txt.
use std::slice;

const MAX_N: usize = 8;
const MAX_E: usize = 28;
const MAX_INPUT: usize = 5 + MAX_N + 3 * MAX_E;
const INF: i64 = 1_000_000_000;

fn push_once(v: usize, queue: &mut [usize; MAX_N], count: &mut usize, seen: &mut [bool; MAX_N]) {
    if !seen[v] { seen[v] = true; queue[*count] = v; *count += 1; }
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn saga_incremental_analytics(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let values = unsafe { slice::from_raw_parts(input, length) };
    let mode64 = values[0]; let n64 = values[1]; let base64 = values[2];
    let added64 = values[3]; let source64 = values[4];
    if !(1..=6).contains(&mode64) || !(2..=MAX_N as i64).contains(&n64) ||
        base64 < 0 || added64 < 1 || base64 + added64 > MAX_E as i64 ||
        length != 5 + n64 as usize + 3 * (base64 + added64) as usize { return -1; }
    let mode = mode64 as usize; let n = n64 as usize;
    let base_edges = base64 as usize; let edge_count = (base64 + added64) as usize;
    if [1usize, 2, 5].contains(&mode) {
        if source64 < 0 || source64 >= n64 { return -1; }
    } else if source64 != -1 { return -1; }

    let mut property = [0i64; MAX_N];
    for v in 0..n {
        let value = values[5 + v];
        let valid = match mode {
            1 => value >= -1 && value < n64,
            2 | 5 => value >= -1 && value <= INF,
            3 => value >= -1 && value <= 1_000_000,
            _ => value >= -1 && value < n64,
        };
        if !valid { return -1; }
        property[v] = value;
    }
    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    let mut weights = [[0i64; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    let mut used = [[false; MAX_N]; MAX_N];
    let mut affected = [false; MAX_N];
    let start = 5 + n;
    for e in 0..edge_count {
        let p = start + 3 * e;
        let u64v = values[p]; let v64v = values[p + 1]; let w = values[p + 2];
        if u64v < 0 || v64v <= u64v || v64v >= n64 || !(1..=9).contains(&w) { return -1; }
        let u = u64v as usize; let v = v64v as usize;
        if used[u][v] { return -1; }
        used[u][v] = true; used[v][u] = true;
        neighbors[u][degree[u]] = v; weights[u][degree[u]] = w; degree[u] += 1;
        neighbors[v][degree[v]] = u; weights[v][degree[v]] = w; degree[v] += 1;
        if e >= base_edges { affected[u] = true; affected[v] = true; }
    }
    if mode == 3 && (0..n).any(|v| degree[v] == 0) { return -1; }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    if mode == 1 && property[source64 as usize] == -1 { property[source64 as usize] = 0; }
    if mode == 2 || mode == 5 {
        for v in 0..n { if property[v] == -1 {
            property[v] = if v == source64 as usize { if mode == 2 { 0 } else { INF } }
                         else if mode == 2 { INF } else { 0 };
        }}
    }
    if mode == 4 || mode == 6 { for v in 0..n { if property[v] == -1 { property[v] = v as i64; } } }
    if mode == 3 {
        let damping = 0.85f32;
        let base = (1.0f32 - damping) / n as f32;
        let mut rank = [0.0f32; MAX_N];
        let mut contribution = [0.0f32; MAX_N];
        for v in 0..n {
            rank[v] = if property[v] == -1 { 1.0f32 / n as f32 } else { property[v] as f32 / 1_000_000.0f32 };
            contribution[v] = rank[v] / degree[v] as f32;
        }
        let mut queue = [0usize; MAX_N]; let mut count = 0usize; let mut seen = [false; MAX_N];
        for v in 0..n { if affected[v] {
            let mut incoming = 0.0f32;
            for j in 0..degree[v] { incoming += contribution[neighbors[v][j]]; }
            let old = rank[v]; rank[v] = base + damping * incoming;
            if (rank[v] - old).abs() > 1.0e-7f32 {
                for j in 0..degree[v] { push_once(neighbors[v][j], &mut queue, &mut count, &mut seen); }
            }
        }}
        let mut rounds = 0;
        while count != 0 {
            rounds += 1; if rounds > 256 { return -1; }
            for v in 0..n { contribution[v] = rank[v] / degree[v] as f32; }
            let current = queue; let current_count = count;
            count = 0; seen = [false; MAX_N];
            for q in 0..current_count {
                let v = current[q]; let mut incoming = 0.0f32;
                for j in 0..degree[v] { incoming += contribution[neighbors[v][j]]; }
                let old = rank[v]; rank[v] = base + damping * incoming;
                if (rank[v] - old).abs() > 1.0e-7f32 {
                    for j in 0..degree[v] { push_once(neighbors[v][j], &mut queue, &mut count, &mut seen); }
                }
            }
        }
        for v in 0..n { property[v] = (rank[v] * 1_000_000.0f32 + 0.5f32).floor() as i64; }
    } else {
        let mut active = [0usize; MAX_N]; let mut active_count = 0usize;
        for v in 0..n { if affected[v] { active[active_count] = v; active_count += 1; } }
        let mut first = true; let mut rounds = 0;
        while active_count != 0 {
            rounds += 1; if rounds > 256 { return -1; }
            let mut next = [0usize; MAX_N]; let mut next_count = 0usize; let mut seen = [false; MAX_N];
            for a in 0..active_count {
                let v = active[a]; let old = property[v];
                let mut candidate = if mode == 1 || mode == 2 || mode == 4 { INF } else { 0 };
                if mode == 1 {
                    for j in 0..degree[v] { let p = property[neighbors[v][j]]; if p != -1 && p + 1 < candidate { candidate = p + 1; } }
                } else if mode == 2 {
                    for j in 0..degree[v] { let p = property[neighbors[v][j]] + weights[v][j]; if p < candidate { candidate = p; } }
                } else if mode == 4 {
                    candidate = old;
                    for j in 0..degree[v] { candidate = candidate.min(property[neighbors[v][j]]); }
                } else if mode == 5 {
                    for j in 0..degree[v] { candidate = candidate.max(property[neighbors[v][j]].min(weights[v][j])); }
                } else {
                    candidate = old;
                    for j in 0..degree[v] { candidate = candidate.max(property[neighbors[v][j]]); }
                }
                let changed = if mode == 1 { candidate != INF && (old == -1 || candidate < old) }
                    else if mode == 2 { candidate < old && candidate != INF }
                    else if mode == 4 { candidate < old || (first && old == v as i64) }
                    else if mode == 5 { candidate > old }
                    else { candidate > old || (first && old == v as i64) };
                if changed {
                    property[v] = candidate;
                    if mode == 1 {
                        for j in 0..degree[v] {
                            let u = neighbors[v][j];
                            let update = candidate + 1;
                            if property[u] == -1 || update < property[u] {
                                property[u] = update;
                                push_once(u, &mut next, &mut next_count, &mut seen);
                            }
                        }
                    } else {
                        for j in 0..degree[v] { push_once(neighbors[v][j], &mut next, &mut next_count, &mut seen); }
                    }
                }
            }
            active = next; active_count = next_count; first = false;
        }
    }
    for v in 0..n { store_i64_le(output, 8 * v, property[v]); }
    output_bytes as i64
}
