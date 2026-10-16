/// Source-faithful bounded Hierholzer traversal for an undirected multigraph.
const MAX_INPUT_LENGTH: usize = 514;

fn hash_record(record: &[i64]) -> i64 {
    let mut hash: u64 = 14695981039346656037;
    for &word in record {
        for byte in word.to_le_bytes() {
            hash ^= u64::from(byte);
            hash = hash.wrapping_mul(1099511628211);
        }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}

#[no_mangle]
pub unsafe extern "C" fn hierholzer_algorithm(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let n_raw = *input;
    let m_raw = *input.add(1);
    if !(0..=8).contains(&n_raw) || !(0..=256).contains(&m_raw) { return -1; }
    let n = n_raw as usize;
    let m = m_raw as usize;
    if length != 2 + 2 * m || (n == 0 && m != 0) { return -1; }
    let mut adj = [[0usize; 512]; 8];
    let mut degree = [0usize; 8];
    for e in 0..m {
        let u = *input.add(2 + 2 * e);
        let v = *input.add(3 + 2 * e);
        if u < 0 || v < 0 || u >= n_raw || v >= n_raw { return -1; }
        let (u, v) = (u as usize, v as usize);
        adj[u][degree[u]] = v; degree[u] += 1;
        adj[v][degree[v]] = u; degree[v] += 1;
    }
    let mut record = [0i64; 259];
    if n == 0 { record[0] = 1; record[1] = 0; return hash_record(&record[..2]); }
    let mut start = 0usize;
    let mut has_edge = false;
    for v in 0..n { if degree[v] > 0 { if !has_edge { start = v; } has_edge = true; } }
    if !has_edge { record[0] = 1; record[1] = 1; record[2] = 0; return hash_record(&record[..3]); }
    let mut seen = [false; 8];
    let mut todo = [0usize; 8];
    let (mut head, mut tail) = (0usize, 1usize); todo[0] = start; seen[start] = true;
    while head < tail {
        let v = todo[head]; head += 1;
        for i in 0..n { if degree[i] > 0 && !seen[i] {
            for j in 0..degree[i] { if adj[i][j] == v { seen[i] = true; todo[tail] = i; tail += 1; break; } }
        } }
    }
    let mut valid = true;
    for v in 0..n { if degree[v] % 2 != 0 || (degree[v] > 0 && !seen[v]) { valid = false; } }
    if !valid { record[0] = 0; record[1] = 0; return hash_record(&record[..2]); }
    let mut lengths = degree;
    let mut stack = [0usize; 258]; let mut stack_len = 1usize; stack[0] = start;
    let mut route = [0usize; 258]; let mut route_len = 0usize;
    while stack_len > 0 {
        let v = stack[stack_len - 1];
        if lengths[v] > 0 {
            let w = adj[v][0];
            for j in 0..lengths[v] - 1 { adj[v][j] = adj[v][j + 1]; }
            lengths[v] -= 1;
            let mut k = 0usize; while k < lengths[w] && adj[w][k] != v { k += 1; }
            if k < lengths[w] {
                for j in k..lengths[w] - 1 { adj[w][j] = adj[w][j + 1]; }
                lengths[w] -= 1;
            }
            stack[stack_len] = w; stack_len += 1;
        } else { stack_len -= 1; route[route_len] = v; route_len += 1; }
    }
    if route_len != m + 1 { record[0] = 0; record[1] = 0; return hash_record(&record[..2]); }
    record[0] = 1; record[1] = route_len as i64;
    for i in 0..route_len { record[2 + i] = route[route_len - 1 - i] as i64; }
    hash_record(&record[..2 + route_len])
}
