const MAX_N: usize = 16;
const MAX_M: usize = 120;
const MAX_D: usize = 4;
const MAX_INPUT: usize = 431;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn max_cut_gw_rounding(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let d64 = *input.add(2);
    if !(2..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || !(1..=MAX_D as i64).contains(&d64)
        || length != 3 + 3 * m64 as usize + n64 as usize * d64 as usize + d64 as usize { return -1; }
    let n = n64 as usize; let m = m64 as usize; let d = d64 as usize;
    let mut edge_u = [0i64; MAX_M]; let mut edge_v = [0i64; MAX_M];
    let mut edge_weight = [0i64; MAX_M];
    let mut previous = (-1i64, -1i64);
    for edge in 0..m {
        let u = *input.add(3 + 3 * edge); let v = *input.add(4 + 3 * edge);
        let weight = *input.add(5 + 3 * edge);
        if u < 0 || v <= u || v >= n64 || !(1..=10000).contains(&weight)
            || (u, v) <= previous { return -1; }
        previous = (u, v); edge_u[edge] = u; edge_v[edge] = v; edge_weight[edge] = weight;
    }
    let vector_offset = 3 + 3 * m;
    let mut vectors = [[0i64; MAX_D]; MAX_N]; let mut normal = [0i64; MAX_D];
    let mut common_norm = 0i64;
    for vertex in 0..n {
        let mut norm = 0i64;
        for axis in 0..d {
            let coordinate = *input.add(vector_offset + vertex * d + axis);
            if !(-100..=100).contains(&coordinate) { return -1; }
            vectors[vertex][axis] = coordinate; norm += coordinate * coordinate;
        }
        if vertex == 0 { common_norm = norm; } else if norm != common_norm { return -1; }
    }
    if common_norm == 0 { return -1; }
    let mut has_normal = false;
    for axis in 0..d {
        normal[axis] = *input.add(vector_offset + n * d + axis);
        if !(-100..=100).contains(&normal[axis]) { return -1; }
        has_normal |= normal[axis] != 0;
    }
    if !has_normal { return -1; }
    let output_bytes = 8 * (n + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut side = [0i64; MAX_N];
    for vertex in 0..n {
        let mut projection = 0i64;
        for axis in 0..d { projection += vectors[vertex][axis] * normal[axis]; }
        side[vertex] = if projection > 0 { 1 } else { 0 };
    }
    let mut cut = 0i64;
    for edge in 0..m { if side[edge_u[edge] as usize] != side[edge_v[edge] as usize] { cut += edge_weight[edge]; } }
    store_i64_le(output, 0, cut);
    for vertex in 0..n { store_i64_le(output, 8 * (vertex + 1), side[vertex]); }
    output_bytes as i64
}
