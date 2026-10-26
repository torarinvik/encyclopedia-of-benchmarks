const N: usize = 16;
const D: usize = 4;
const MAX_EDGES: usize = 32;
const MAX_T: usize = 4;
const MAX_R: usize = 8;
const MAX_L: usize = 8;
const MAX_INPUT: usize = 330;

fn put(out: &mut [u8], value: i64) { out[..8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn sublinear_bipartiteness_walk_tester(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 8 || length > MAX_INPUT { return -1; }
    let n0, d0, m0 = (*values, *values.add(1), *values.add(2));
    if !(1..=N as i64).contains(&n0) || !(3..=D as i64).contains(&d0) || m0 < 0 || m0 > MAX_EDGES as i64 { return -1; }
    let (n, d, m) = (n0 as usize, d0 as usize, m0 as usize);
    if m > n * d / 2 { return -1; }
    let suffix = 3 + 2 * m;
    if length < suffix + 4 { return -1; }
    let (t0, r0, l0) = (*values.add(suffix), *values.add(suffix + 1), *values.add(suffix + 2));
    if !(1..=MAX_T as i64).contains(&t0) || !(1..=MAX_R as i64).contains(&r0) || !(1..=MAX_L as i64).contains(&l0) { return -1; }
    let (starts_count, walks, steps) = (t0 as usize, r0 as usize, l0 as usize);
    if length != suffix + 3 + starts_count + starts_count * walks * steps { return -1; }
    let mut adjacent = [[false; N]; N];
    let mut neighbors = [[0usize; D]; N];
    let mut degree = [0usize; N];
    for edge in 0..m {
        let a0 = *values.add(3 + 2 * edge);
        let b0 = *values.add(4 + 2 * edge);
        if a0 < 0 || b0 < 0 || a0 >= n0 || b0 >= n0 || a0 >= b0 { return -1; }
        let (a, b) = (a0 as usize, b0 as usize);
        if adjacent[a][b] || degree[a] >= d || degree[b] >= d { return -1; }
        adjacent[a][b] = true; adjacent[b][a] = true;
        let mut at = degree[a]; degree[a] += 1;
        while at > 0 && neighbors[a][at - 1] > b { neighbors[a][at] = neighbors[a][at - 1]; at -= 1; }
        neighbors[a][at] = b;
        at = degree[b]; degree[b] += 1;
        while at > 0 && neighbors[b][at - 1] > a { neighbors[b][at] = neighbors[b][at - 1]; at -= 1; }
        neighbors[b][at] = a;
    }
    let starts_at = suffix + 3;
    let draws_at = starts_at + starts_count;
    for t in 0..starts_count {
        let start = *values.add(starts_at + t);
        if start < 0 || start >= n0 { return -1; }
    }
    let draw_count = starts_count * walks * steps;
    for index in 0..draw_count {
        let choice = *values.add(draws_at + index);
        if choice < 0 || choice >= (2 * d) as i64 { return -1; }
    }
    let mut accepted = true;
    let mut draw = 0usize;
    for t in 0..starts_count {
        if !accepted { break; }
        let mut seen = [[false; 2]; N];
        let start = *values.add(starts_at + t) as usize;
        seen[start][0] = true;
        for _walk in 0..walks {
            if !accepted { break; }
            let (mut vertex, mut parity) = (start, 0usize);
            for _step in 0..steps {
                let choice = *values.add(draws_at + draw) as usize;
                draw += 1;
                if choice < degree[vertex] { vertex = neighbors[vertex][choice]; parity ^= 1; }
                seen[vertex][parity] = true;
                if seen[vertex][1 - parity] { accepted = false; break; }
            }
        }
    }
    if output.is_null() || capacity < 8 { return -2; }
    let mut staged = [0u8; 8]; put(&mut staged, if accepted { 1 } else { 0 });
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, 8);
    8
}
