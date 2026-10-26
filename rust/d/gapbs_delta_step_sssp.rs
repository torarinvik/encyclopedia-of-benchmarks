// Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 4 + 3 * MAX_M;
const MAX_BUCKETS: usize = 481;
const MAX_EVENTS: usize = 8192;
const INF_DISTANCE: i64 = 1_073_741_823;

fn append_event(
    bucket: usize, vertex: usize,
    heads: &mut [i32; MAX_BUCKETS], tails: &mut [i32; MAX_BUCKETS],
    event_vertex: &mut [i32; MAX_EVENTS], event_next: &mut [i32; MAX_EVENTS],
    used: &mut usize,
) -> bool {
    if bucket >= MAX_BUCKETS || *used >= MAX_EVENTS { return false; }
    let event = *used as i32;
    *used += 1;
    event_vertex[event as usize] = vertex as i32;
    event_next[event as usize] = -1;
    if heads[bucket] < 0 { heads[bucket] = event; }
    else { event_next[tails[bucket] as usize] = event; }
    tails[bucket] = event;
    true
}

#[no_mangle]
pub unsafe extern "C" fn gapbs_delta_step_sssp(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let source64 = *input.add(2);
    let delta64 = *input.add(3);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || source64 < 0 || source64 >= n64 || !(1..=16).contains(&delta64)
        || length != 4 + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let delta = delta64;
    let mut edges = [(0usize, 0usize, 0i64); MAX_M];
    for edge in 0..m {
        let from = *input.add(4 + 3 * edge);
        let to = *input.add(5 + 3 * edge);
        let weight = *input.add(6 + 3 * edge);
        if from < 0 || from >= n64 || to < 0 || to >= n64 || !(0..=32).contains(&weight) { return -1; }
        edges[edge] = (from as usize, to as usize, weight);
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut distance = [INF_DISTANCE; MAX_N];
    distance[source64 as usize] = 0;
    let mut heads = [-1i32; MAX_BUCKETS];
    let mut tails = [-1i32; MAX_BUCKETS];
    let mut event_vertex = [0i32; MAX_EVENTS];
    let mut event_next = [-1i32; MAX_EVENTS];
    let mut used = 0usize;
    if !append_event(0, source64 as usize, &mut heads, &mut tails,
        &mut event_vertex, &mut event_next, &mut used) { return -1; }
    for bucket in 0..MAX_BUCKETS {
        while heads[bucket] >= 0 {
            let event = heads[bucket] as usize;
            heads[bucket] = event_next[event];
            if heads[bucket] < 0 { tails[bucket] = -1; }
            let u = event_vertex[event] as usize;
            if distance[u] < delta * bucket as i64 { continue; }
            for &(from, to, weight) in edges[..m].iter() {
                if from != u { continue; }
                let candidate = distance[u] + weight;
                if candidate < distance[to] {
                    distance[to] = candidate;
                    if !append_event((candidate / delta) as usize, to, &mut heads, &mut tails,
                        &mut event_vertex, &mut event_next, &mut used) { return -1; }
                }
            }
        }
    }
    for vertex in 0..n {
        let bits = distance[vertex] as u64;
        for byte in 0..8 { *output.add(8 * vertex + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
