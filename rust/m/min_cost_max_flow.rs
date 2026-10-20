// Based on AtCoder Library mcf_graph::flow (CC0 1.0); see benchmarks/m/min_cost_max_flow/LICENSE.txt.
use std::slice;

const INF: i64 = 1_i64 << 60;
#[derive(Clone, Copy)]
struct Edge { from: usize, to: usize, rev: usize, cap: i64, cost: i64 }

#[no_mangle]
pub unsafe extern "C" fn min_cost_max_flow(input: *const i64, length: usize,
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
    let mut potential = [0_i64; 8];
    let (mut total_flow, mut total_cost) = (0_i64, 0_i64);
    while total_flow < flow_limit {
        let mut dist = [INF; 8];
        let mut parent = [usize::MAX; 8];
        let mut used = [false; 8];
        dist[source] = 0;
        for _ in 0..n {
            let mut chosen = usize::MAX;
            for v in 0..n {
                if !used[v] && dist[v] != INF && (chosen == usize::MAX || dist[v] < dist[chosen]) { chosen = v; }
            }
            if chosen == usize::MAX { break; }
            used[chosen] = true;
            for e in 0..2*m {
                if edges[e].from != chosen || edges[e].cap <= 0 { continue; }
                let v = edges[e].to;
                let candidate = dist[chosen] + edges[e].cost + potential[chosen] - potential[v];
                if !used[v] && candidate < dist[v] { dist[v] = candidate; parent[v] = e; }
            }
        }
        if dist[sink] == INF { break; }
        for v in 0..n { if dist[v] != INF { potential[v] += dist[v]; } }
        let mut amount = flow_limit - total_flow;
        let mut v = sink;
        while v != source {
            let e = parent[v];
            if e == usize::MAX { return -1; }
            amount = amount.min(edges[e].cap);
            v = edges[e].from;
        }
        v = sink;
        while v != source {
            let e = parent[v];
            let reverse = edges[e].rev;
            edges[e].cap -= amount;
            edges[reverse].cap += amount;
            v = edges[e].from;
        }
        total_flow += amount;
        total_cost += amount * (potential[sink] - potential[source]);
    }
    let out = slice::from_raw_parts_mut(output, 16);
    out[..8].copy_from_slice(&total_flow.to_le_bytes());
    out[8..].copy_from_slice(&total_cost.to_le_bytes());
    16
}
