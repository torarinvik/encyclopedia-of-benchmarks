fn put_i64(output: &mut [u8], value: i64) { output[..8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn approximating_diameter_bfs(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 242 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n0 = values[0]; let m0 = values[1];
    if !(1..=16).contains(&n0) || !(0..=120).contains(&m0) || length != 2 + 2 * m0 as usize { return -1; }
    let n = n0 as usize; let m = m0 as usize;
    let mut adj = [[false; 16]; 16];
    for i in 0..m {
        let u0 = values[2 + 2*i]; let v0 = values[3 + 2*i];
        if u0 < 0 || v0 <= u0 || v0 >= n0 { return -1; }
        let u = u0 as usize; let v = v0 as usize;
        if adj[u][v] { return -1; }
        adj[u][v] = true; adj[v][u] = true;
    }
    let mut dist = [-1i64; 16]; let mut queue = [0usize; 16];
    dist[0] = 0; queue[0] = 0; let mut head = 0usize; let mut tail = 1usize;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..n {
            if adj[u][v] && dist[v] < 0 { dist[v] = dist[u] + 1; queue[tail] = v; tail += 1; }
        }
    }
    if tail != n { return -1; }
    let estimate = *dist[..n].iter().max().unwrap();
    if output.is_null() || capacity < 8 { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, 8);
    put_i64(dst, estimate); 8
}
