const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 60;

unsafe fn put(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *out.add(at + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn nagamochi_ibaraki_sparse_k_connectivity_certificate(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let k64 = *input.add(2);
    if !(3..=8).contains(&n64) || !(0..=28).contains(&m64) || !(1..=3).contains(&k64)
        || length != 3 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let k = k64 as usize;
    let mut u = [0usize; MAX_M];
    let mut v = [0usize; MAX_M];
    let mut incident = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for e in 0..m {
        let a = *input.add(3 + 2 * e);
        let b = *input.add(4 + 2 * e);
        if a < 0 || a >= b || b >= n64 { return -1; }
        u[e] = a as usize;
        v[e] = b as usize;
        for prior in 0..e { if u[prior] == u[e] && v[prior] == v[e] { return -1; } }
        incident[u[e]][degree[u[e]]] = e;
        degree[u[e]] += 1;
        incident[v[e]][degree[v[e]]] = e;
        degree[v[e]] += 1;
    }
    let bytes = 8 * (m + 1);
    if output.is_null() || capacity < bytes { return -2; }

    let mut rank = [0usize; MAX_N];
    let mut layer = [0usize; MAX_M];
    let mut scanned_vertex = [false; MAX_N];
    let mut scanned_edge = [false; MAX_M];
    for _ in 0..n {
        let mut x = n;
        for vertex in 0..n {
            if !scanned_vertex[vertex] && (x == n || rank[vertex] > rank[x]) { x = vertex; }
        }
        for slot in 0..degree[x] {
            let e = incident[x][slot];
            if scanned_edge[e] { continue; }
            let y = if u[e] == x { v[e] } else { u[e] };
            layer[e] = rank[y] + 1;
            if rank[x] == rank[y] { rank[x] += 1; }
            rank[y] += 1;
            scanned_edge[e] = true;
        }
        scanned_vertex[x] = true;
    }
    put(output, 0, m as i64);
    for e in 0..m { put(output, 8 * (e + 1), if layer[e] <= k { layer[e] as i64 } else { 0 }); }
    bytes as i64
}
