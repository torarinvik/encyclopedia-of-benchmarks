// Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn gapbs_ordered_triangle_count(input: *const i64, length: usize) -> i64 {
    const MAX_N: usize = 16;
    if input.is_null() || length < 2 || length > 1 + MAX_N * MAX_N { return -1; }
    let raw_n = *input;
    if !(1..=MAX_N as i64).contains(&raw_n) { return -1; }
    let n = raw_n as usize;
    if length != 1 + n * n { return -1; }
    let mut adjacency = [[0i64; MAX_N]; MAX_N];
    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for u in 0..n {
        for v in 0..n {
            let edge = *input.add(1 + u * n + v);
            if edge != 0 && edge != 1 { return -1; }
            if u == v && edge != 0 { return -1; }
            adjacency[u][v] = edge;
        }
    }
    for u in 0..n {
        for v in (u + 1)..n {
            if adjacency[u][v] != adjacency[v][u] { return -1; }
        }
    }
    for u in 0..n {
        for v in 0..n {
            if adjacency[u][v] != 0 {
                neighbors[u][degree[u]] = v;
                degree[u] += 1;
            }
        }
    }
    let mut total = 0i64;
    for u in 0..n {
        for vi in 0..degree[u] {
            let v = neighbors[u][vi];
            if v > u { break; }
            let mut edge_pos = 0usize;
            for wi in 0..degree[u] {
                let w = neighbors[u][wi];
                if w > v { break; }
                while edge_pos < degree[v] && neighbors[v][edge_pos] < w { edge_pos += 1; }
                if edge_pos < degree[v] && neighbors[v][edge_pos] == w { total += 1; }
            }
        }
    }
    total
}
