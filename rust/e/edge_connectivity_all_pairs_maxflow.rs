const MAX_VERTICES: usize = 10;
const MAX_EDGES: usize = 45;
const MAX_PARSEABLE: usize = 93;

fn pair_flow(
    adjacency: &[[i64; MAX_VERTICES]; MAX_VERTICES],
    n: usize,
    source: usize,
    sink: usize,
    limit: i64,
) -> i64 {
    let mut residual = *adjacency;
    let mut flow = 0i64;
    while flow < limit {
        let mut parent = [-1i32; MAX_VERTICES];
        let mut queue = [0usize; MAX_VERTICES];
        parent[source] = source as i32;
        let mut head = 0usize;
        let mut tail = 0usize;
        queue[tail] = source;
        tail += 1;
        while head < tail && parent[sink] < 0 {
            let u = queue[head];
            head += 1;
            for v in 0..n {
                if parent[v] < 0 && residual[u][v] > 0 {
                    parent[v] = u as i32;
                    queue[tail] = v;
                    tail += 1;
                    if v == sink { break; }
                }
            }
        }
        if parent[sink] < 0 { break; }
        let mut amount = limit - flow;
        let mut v = sink;
        while v != source {
            let u = parent[v] as usize;
            amount = amount.min(residual[u][v]);
            v = u;
        }
        v = sink;
        while v != source {
            let u = parent[v] as usize;
            residual[u][v] -= amount;
            residual[v][u] += amount;
            v = u;
        }
        flow += amount;
    }
    flow
}

#[no_mangle]
pub unsafe extern "C" fn edge_connectivity_all_pairs_maxflow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 2 || values[0] > MAX_VERTICES as i64 || values[1] < 0 || values[1] > MAX_EDGES as i64 { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2 * m { return -1; }

    let mut adjacency = [[0i64; MAX_VERTICES]; MAX_VERTICES];
    for e in 0..m {
        let left = values[2 + 2 * e];
        let right = values[3 + 2 * e];
        if left < 0 || right < 0 || left >= n as i64 || right >= n as i64 || left == right { return -1; }
        let u = left as usize;
        let v = right as usize;
        if adjacency[u][v] != 0 { return -1; }
        adjacency[u][v] = 1;
        adjacency[v][u] = 1;
    }

    let mut best = n as i64 - 1;
    for source in 0..n {
        for sink in (source + 1)..n {
            let flow = pair_flow(&adjacency, n, source, sink, best);
            if flow < best { best = flow; }
            if best == 0 { return 0; }
        }
    }
    best
}
