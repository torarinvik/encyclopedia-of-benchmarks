/* Clean-room exact dyadic projection of GBBS CoSimRank; see package LICENSE.txt. */
const MAX_N: usize = 8;
const MAX_M: usize = 24;
const MAX_INPUT: usize = 53;

fn store_scaled_binary64(output: *mut u8, numerator: u32) {
    let mut bits = 0u64;
    if numerator != 0 {
        let high = 31 - numerator.leading_zeros();
        let exponent = (1003 + high) as u64;
        let significand = (numerator as u64) << (52 - high);
        bits = (exponent << 52) | (significand & ((1u64 << 52) - 1));
    }
    for byte in 0..8 { unsafe { *output.add(byte) = (bits & 255) as u8; } bits >>= 8; }
}

#[no_mangle]
pub unsafe extern "C" fn gbbs_cosimrank_pair_similarity(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let source_u64 = *input.add(2);
    let source_v64 = *input.add(3);
    let iterations64 = *input.add(4);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64) ||
        source_u64 < 0 || source_u64 >= n64 || source_v64 < 0 || source_v64 >= n64 ||
        !(1..=4).contains(&iterations64) || length != 5 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut from = [0usize; MAX_M];
    let mut to = [0usize; MAX_M];
    let mut degree = [0usize; MAX_N];
    let mut seen = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let a64 = *input.add(5 + 2 * edge);
        let b64 = *input.add(6 + 2 * edge);
        if a64 < 0 || a64 >= n64 || b64 < 0 || b64 >= n64 || a64 == b64 { return -1; }
        let a = a64 as usize; let b = b64 as usize;
        if seen[a][b] { return -1; }
        seen[a][b] = true; from[edge] = a; to[edge] = b; degree[a] += 1;
    }
    for d in degree.iter().take(n) { if *d != 0 && *d != 1 && *d != 2 && *d != 4 { return -1; } }
    if output.is_null() || capacity < 8 { return -2; }
    let mut current_u = [0u32; MAX_N]; let mut current_v = [0u32; MAX_N];
    let mut next_u = [0u32; MAX_N]; let mut next_v = [0u32; MAX_N];
    current_u[source_u64 as usize] = 256; current_v[source_v64 as usize] = 256;
    let mut numerator = if source_u64 == source_v64 { 1u32 << 20 } else { 0 };
    for step in 0..iterations64 as usize {
        for edge in 0..m {
            let a = from[edge]; let b = to[edge];
            next_u[b] += current_u[a] / degree[a] as u32;
            next_v[b] += current_v[a] / degree[a] as u32;
        }
        let mut dot = 0u32;
        for vertex in 0..n { dot += next_u[vertex] * next_v[vertex]; }
        numerator += dot << (3 - step);
        for vertex in 0..n {
            current_u[vertex] = next_u[vertex]; current_v[vertex] = next_v[vertex];
            next_u[vertex] = 0; next_v[vertex] = 0;
        }
    }
    store_scaled_binary64(output, numerator);
    8
}
