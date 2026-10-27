const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 88;
const INF: i64 = 1i64 << 60;

#[derive(Clone, Copy, Default)]
struct Edge { u: i64, v: i64, weight: i64, original: usize }

#[no_mangle]
pub unsafe extern "C" fn weighted_greedy_spanner(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n64, m64, k) = (values[0], values[1], values[2]);
    if !(2..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64) || !(1..=3).contains(&k)
        || length != 3 + 3 * m64 as usize { return -1; }
    let (n, m) = (n64 as usize, m64 as usize);
    let mut edges = [Edge::default(); MAX_M];
    let mut selected = [0u8; MAX_M];
    let mut adjacency = [[0i64; MAX_N]; MAX_N];
    for i in 0..m {
        let edge = Edge { u: values[3 + 3 * i], v: values[4 + 3 * i], weight: values[5 + 3 * i], original: i };
        if edge.u < 0 || edge.v <= edge.u || edge.v >= n64 || !(1..=32).contains(&edge.weight) { return -1; }
        if edges[..i].iter().any(|prior| prior.u == edge.u && prior.v == edge.v) { return -1; }
        edges[i] = edge;
    }
    for i in 1..m {
        let key = edges[i];
        let mut pos = i;
        while pos > 0 {
            let prev = edges[pos - 1];
            if (prev.weight, prev.u, prev.v) <= (key.weight, key.u, key.v) { break; }
            edges[pos] = prev; pos -= 1;
        }
        edges[pos] = key;
    }
    if output.is_null() || capacity < m { return -2; }
    for edge in edges.iter().take(m) {
        let source = edge.u as usize;
        let target = edge.v as usize;
        let mut distance = [INF; MAX_N];
        let mut settled = [false; MAX_N];
        distance[source] = 0;
        for _ in 0..n {
            let mut vertex = n;
            for v in 0..n {
                if !settled[v] && (vertex == n || distance[v] < distance[vertex]) { vertex = v; }
            }
            if vertex == n || distance[vertex] == INF { break; }
            settled[vertex] = true;
            for v in 0..n {
                if adjacency[vertex][v] > 0 && distance[v] > distance[vertex] + adjacency[vertex][v] {
                    distance[v] = distance[vertex] + adjacency[vertex][v];
                }
            }
        }
        if distance[target] > (2 * k - 1) * edge.weight {
            selected[edge.original] = 1;
            adjacency[source][target] = edge.weight;
            adjacency[target][source] = edge.weight;
        }
    }
    std::ptr::copy_nonoverlapping(selected.as_ptr(), output, m);
    m as i64
}
