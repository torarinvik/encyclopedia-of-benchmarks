const MAX_N: usize = 16;
const MAX_M: usize = 120;
const MAX_INPUT: usize = 362;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn max_cut_sahni_gonzalez(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut weights = [[0i64; MAX_N]; MAX_N];
    let mut seen = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(2 + 3 * edge);
        let v64 = *input.add(3 + 3 * edge);
        let weight = *input.add(4 + 3 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 || !(0..=10000).contains(&weight) { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if seen[u][v] { return -1; }
        seen[u][v] = true;
        weights[u][v] = weight;
        weights[v][u] = weight;
    }
    let output_bytes = 8 * (n + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut side = [0i64; MAX_N];
    for vertex in 0..n {
        let mut put_zero = 0i64;
        let mut put_one = 0i64;
        for prior in 0..vertex {
            if side[prior] == 1 { put_zero += weights[prior][vertex]; }
            else { put_one += weights[prior][vertex]; }
        }
        side[vertex] = if put_one > put_zero { 1 } else { 0 };
    }
    let mut cut = 0i64;
    for u in 0..n {
        for v in (u + 1)..n {
            if side[u] != side[v] { cut += weights[u][v]; }
        }
    }
    store_i64_le(output, 0, cut);
    for vertex in 0..n { store_i64_le(output, 8 * (vertex + 1), side[vertex]); }
    output_bytes as i64
}
