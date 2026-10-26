const N: usize = 16;
const MAX_EDGES: usize = 120;
const MAX_INPUT: usize = 242;
const MAX_OUTPUT: usize = 2064;

fn put(out: &mut [u8], offset: usize, value: i64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn treewidth_min_fill_elimination(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n0 = *values;
    let m0 = *values.add(1);
    if !(1..=N as i64).contains(&n0) || m0 < 0 || m0 > MAX_EDGES as i64 { return -1; }
    let n = n0 as usize;
    let m = m0 as usize;
    if m > n * (n - 1) / 2 || length != 2 + 2 * m { return -1; }
    let mut adjacent = [[false; N]; N];
    for edge in 0..m {
        let a0 = *values.add(2 + 2 * edge);
        let b0 = *values.add(3 + 2 * edge);
        if a0 < 0 || b0 < 0 || a0 >= n0 || b0 >= n0 || a0 >= b0 { return -1; }
        let (a, b) = (a0 as usize, b0 as usize);
        if adjacent[a][b] { return -1; }
        adjacent[a][b] = true;
        adjacent[b][a] = true;
    }
    let mut active = [false; N];
    active[..n].fill(true);
    let mut order = [0i64; N];
    let mut fill_u = [0i64; MAX_EDGES];
    let mut fill_v = [0i64; MAX_EDGES];
    let mut width = 0usize;
    let mut fill_count = 0usize;
    for step in 0..n {
        let mut chosen = usize::MAX;
        let mut chosen_fill = MAX_EDGES + 1;
        let mut chosen_degree = 0usize;
        for vertex in 0..n {
            if !active[vertex] { continue; }
            let mut neighbors = [0usize; N];
            let mut neighbor_count = 0usize;
            for other in 0..n {
                if active[other] && adjacent[vertex][other] {
                    neighbors[neighbor_count] = other;
                    neighbor_count += 1;
                }
            }
            let mut missing = 0usize;
            for i in 0..neighbor_count {
                for j in i + 1..neighbor_count {
                    if !adjacent[neighbors[i]][neighbors[j]] { missing += 1; }
                }
            }
            if missing < chosen_fill { chosen = vertex; chosen_fill = missing; chosen_degree = neighbor_count; }
        }
        order[step] = chosen as i64;
        width = width.max(chosen_degree);
        let mut neighbors = [0usize; N];
        let mut neighbor_count = 0usize;
        for other in 0..n {
            if active[other] && adjacent[chosen][other] { neighbors[neighbor_count] = other; neighbor_count += 1; }
        }
        for i in 0..neighbor_count {
            for j in i + 1..neighbor_count {
                let (a, b) = (neighbors[i], neighbors[j]);
                if !adjacent[a][b] {
                    adjacent[a][b] = true;
                    adjacent[b][a] = true;
                    fill_u[fill_count] = a as i64;
                    fill_v[fill_count] = b as i64;
                    fill_count += 1;
                }
            }
        }
        active[chosen] = false;
    }
    let bytes = 8 * (n + 2 + 2 * fill_count);
    if output.is_null() || capacity < bytes || bytes > MAX_OUTPUT { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    put(&mut staged, 0, width as i64);
    for i in 0..n { put(&mut staged, 8 * (i + 1), order[i]); }
    put(&mut staged, 8 * (n + 1), fill_count as i64);
    for i in 0..fill_count {
        put(&mut staged, 8 * (n + 2 + 2 * i), fill_u[i]);
        put(&mut staged, 8 * (n + 3 + 2 * i), fill_v[i]);
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
