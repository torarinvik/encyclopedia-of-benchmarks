// Clean-room shortest-path tight-edge blocking-flow method; see package RIGHTS.md.
use std::slice;

const INF: i64 = 1_i64 << 60;
#[derive(Clone, Copy)]
struct Edge { from: usize, to: usize, rev: usize, cap: i64, cost: i64 }

fn send_tight_level_flow(u: usize, sink: usize, limit: i64, edges: &mut [Edge; 32],
    arc_count: usize, dist: &[i64; 8], level: &[i32; 8], current: &mut [usize; 8]) -> i64 {
    if u == sink { return limit; }
    while current[u] < arc_count {
        let e = current[u];
        if edges[e].from != u || edges[e].cap <= 0 { current[u] += 1; continue; }
        let v = edges[e].to;
        if dist[v] == INF || dist[v] != dist[u] + edges[e].cost || level[v] != level[u] + 1 {
            current[u] += 1; continue;
        }
        let amount = limit.min(edges[e].cap);
        let sent = send_tight_level_flow(v, sink, amount, edges, arc_count, dist, level, current);
        if sent > 0 {
            let reverse = edges[e].rev;
            edges[e].cap -= sent;
            edges[reverse].cap += sent;
            if edges[e].cap == 0 { current[u] += 1; }
            return sent;
        }
        current[u] += 1;
    }
    0
}

#[no_mangle]
pub unsafe extern "C" fn min_cost_max_flow_blocking_paths(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 69 { return -1; }
    let values = slice::from_raw_parts(input, length);
    let (n0, m0, s0, t0, flow_limit) = (values[0], values[1], values[2], values[3], values[4]);
    if !(2..=8).contains(&n0) || !(0..=16).contains(&m0) || length != 5 + 4 * m0 as usize { return -1; }
    let n = n0 as usize;
    if s0 < 0 || s0 >= n0 || t0 < 0 || t0 >= n0 || s0 == t0 || !(0..=16).contains(&flow_limit) { return -1; }
    let (source, sink) = (s0 as usize, t0 as usize);
    let m = m0 as usize;
    let mut edges = [Edge { from: 0, to: 0, rev: 0, cap: 0, cost: 0 }; 32];
    for i in 0..m {
        let (u, v, cap, cost) = (values[5 + 4*i], values[6 + 4*i], values[7 + 4*i], values[8 + 4*i]);
        if u < 0 || u >= n0 || v < 0 || v >= n0 || !(0..=5).contains(&cap) || !(0..=20).contains(&cost) { return -1; }
        let e = 2 * i;
        edges[e] = Edge { from: u as usize, to: v as usize, rev: e + 1, cap, cost };
        edges[e+1] = Edge { from: v as usize, to: u as usize, rev: e, cap: 0, cost: -cost };
    }
    if output.is_null() || output_capacity < 16 { return -2; }
    let (mut total_flow, mut total_cost) = (0_i64, 0_i64);
    while total_flow < flow_limit {
        let mut dist = [INF; 8];
        let mut queue = [0_usize; 8];
        let mut in_queue = [false; 8];
        dist[source] = 0;
        let (mut head, mut tail, mut queued) = (0_usize, 0_usize, 0_usize);
        queue[tail] = source; tail = (tail + 1) % n; queued += 1; in_queue[source] = true;
        while queued > 0 {
            let u = queue[head]; head = (head + 1) % n; queued -= 1; in_queue[u] = false;
            for e in 0..2*m {
                if edges[e].from != u || edges[e].cap <= 0 { continue; }
                let v = edges[e].to;
                let candidate = dist[u] + edges[e].cost;
                if candidate < dist[v] {
                    dist[v] = candidate;
                    if !in_queue[v] {
                        queue[tail] = v; tail = (tail + 1) % n; queued += 1; in_queue[v] = true;
                    }
                }
            }
        }
        if dist[sink] == INF { break; }
        while total_flow < flow_limit {
            let mut level = [-1_i32; 8];
            let mut breadth = [0_usize; 8];
            let mut current = [0_usize; 8];
            let (mut first, mut last) = (0_usize, 0_usize);
            level[source] = 0; breadth[last] = source; last += 1;
            while first < last {
                let u = breadth[first]; first += 1;
                for e in 0..2*m {
                    if edges[e].from != u || edges[e].cap <= 0 { continue; }
                    let v = edges[e].to;
                    if dist[v] == dist[u] + edges[e].cost && level[v] < 0 {
                        level[v] = level[u] + 1; breadth[last] = v; last += 1;
                    }
                }
            }
            if level[sink] < 0 { break; }
            let amount = send_tight_level_flow(source, sink, flow_limit - total_flow,
                &mut edges, 2*m, &dist, &level, &mut current);
            if amount == 0 { break; }
            total_flow += amount;
            total_cost += amount * dist[sink];
        }
    }
    let out = slice::from_raw_parts_mut(output, 16);
    out[..8].copy_from_slice(&total_flow.to_le_bytes());
    out[8..].copy_from_slice(&total_cost.to_le_bytes());
    16
}
