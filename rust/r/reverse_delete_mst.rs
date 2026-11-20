const MAX_N: usize = 8;
const MAX_M: usize = 20;
const MAX_INPUT: usize = 63;

#[derive(Clone, Copy, Default)]
struct Edge { u: usize, v: usize, weight: i64 }

fn graph_connected(n: usize, edges: &[Edge; MAX_M], m: usize, active: u32) -> bool {
    let mut seen = [false; MAX_N];
    let mut queue = [0usize; MAX_N];
    let (mut head, mut tail) = (0usize, 0usize);
    seen[0] = true;
    queue[tail] = 0;
    tail += 1;
    while head < tail {
        let vertex = queue[head];
        head += 1;
        for id in 0..m {
            if ((active >> id) & 1) == 0 { continue; }
            let edge = edges[id];
            let neighbor = if edge.u == vertex { Some(edge.v) }
                else if edge.v == vertex { Some(edge.u) }
                else { None };
            if let Some(other) = neighbor {
                if !seen[other] {
                    seen[other] = true;
                    queue[tail] = other;
                    tail += 1;
                }
            }
        }
    }
    seen[..n].iter().all(|&value| value)
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn reverse_delete_mst(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_ptr, length) };
    if input[0] < 2 || input[0] > MAX_N as i64 || input[1] < input[0] - 1 || input[1] > MAX_M as i64 { return -1; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if length != 2 + 3 * m { return -1; }
    let mut edges = [Edge::default(); MAX_M];
    let mut order = [0usize; MAX_M];
    for id in 0..m {
        let u = input[2 + 3 * id];
        let v = input[3 + 3 * id];
        let weight = input[4 + 3 * id];
        if u < 0 || u >= n as i64 || v < 0 || v >= n as i64 || u == v || !(0..=1000).contains(&weight) { return -1; }
        edges[id] = Edge { u: u as usize, v: v as usize, weight };
        order[id] = id;
        let pair = (u.min(v), u.max(v));
        for prior in 0..id {
            let other = edges[prior];
            if pair == ((other.u.min(other.v) as i64), (other.u.max(other.v) as i64)) { return -1; }
        }
    }
    for i in 1..m {
        let item = order[i];
        let mut j = i;
        while j > 0 && (edges[order[j - 1]].weight < edges[item].weight ||
            (edges[order[j - 1]].weight == edges[item].weight && order[j - 1] < item)) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = item;
    }
    let mut active = (1u32 << m) - 1;
    if !graph_connected(n, &edges, m, active) { return -1; }
    for position in 0..m {
        let candidate = active & !(1u32 << order[position]);
        if graph_connected(n, &edges, m, candidate) { active = candidate; }
    }
    let total_weight: i64 = (0..m).filter(|&id| ((active >> id) & 1) != 0).map(|id| edges[id].weight).sum();
    if output_ptr.is_null() || capacity < 16 { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output_ptr, 16) };
    store_i64_le(output, 0, active as i64);
    store_i64_le(output, 8, total_weight);
    16
}
