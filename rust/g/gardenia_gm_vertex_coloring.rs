// Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 130;
const MAX_COLOR: i32 = 128;

#[no_mangle]
pub unsafe extern "C" fn gardenia_gm_vertex_coloring(input: *const i64,
        length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adjacent = [[false; MAX_N]; MAX_N];
    for e in 0..m {
        let u64 = *input.add(2 + 2 * e);
        let v64 = *input.add(3 + 2 * e);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut colors = [MAX_COLOR; MAX_N];
    let mut prior = [MAX_COLOR; MAX_N];
    let mut pending = [0usize; MAX_N];
    let mut next_pending = [0usize; MAX_N];
    for u in 0..n { pending[u] = u; }
    let mut pending_count = n;
    let mut rounds = 0;
    while pending_count > 0 {
        rounds += 1;
        if rounds > n + 1 { return -1; }
        prior = colors;
        for item in 0..pending_count {
            let u = pending[item];
            let mut forbidden = [false; MAX_N];
            for v in 0..n {
                if adjacent[u][v] && prior[v] != MAX_COLOR {
                    forbidden[prior[v] as usize] = true;
                }
            }
            let mut color = 0usize;
            while color < MAX_COLOR as usize && forbidden[color] { color += 1; }
            if color >= MAX_COLOR as usize { return -1; }
            colors[u] = color as i32;
        }
        let mut next_count = 0;
        for item in 0..pending_count {
            let u = pending[item];
            let mut conflict = false;
            for v in u + 1..n {
                if adjacent[u][v] && colors[u] == colors[v] { conflict = true; break; }
            }
            if conflict {
                colors[u] = MAX_COLOR;
                next_pending[next_count] = u;
                next_count += 1;
            }
        }
        pending_count = next_count;
        pending[..pending_count].copy_from_slice(&next_pending[..pending_count]);
    }
    for u in 0..n {
        let bits = colors[u] as u64;
        for byte in 0..8 { *output.add(8 * u + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
