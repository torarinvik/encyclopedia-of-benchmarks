const N: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 58;
const MAX_OUTPUT: usize = 72;

fn put(out: &mut [u8], offset: usize, value: i64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn treewidth_exact_elimination_order(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let (n0, m0) = (*values, *values.add(1));
    if !(1..=N as i64).contains(&n0) || m0 < 0 || m0 > MAX_EDGES as i64 { return -1; }
    let (n, m) = (n0 as usize, m0 as usize);
    if m > n * (n - 1) / 2 || length != 2 + 2 * m { return -1; }
    let mut base = [[false; N]; N];
    for edge in 0..m {
        let a0 = *values.add(2 + 2 * edge);
        let b0 = *values.add(3 + 2 * edge);
        if a0 < 0 || b0 < 0 || a0 >= n0 || b0 >= n0 || a0 >= b0 { return -1; }
        let (a, b) = (a0 as usize, b0 as usize);
        if base[a][b] { return -1; }
        base[a][b] = true; base[b][a] = true;
    }
    let mut permutation = [0usize; N];
    let mut best_order = [0usize; N];
    for i in 0..n { permutation[i] = i; }
    let mut best_width = N + 1;
    loop {
        let mut adjacent = base;
        let mut active = [false; N];
        active[..n].fill(true);
        let mut width = 0usize;
        for step in 0..n {
            let vertex = permutation[step];
            let mut neighbors = [0usize; N];
            let mut count = 0usize;
            for other in 0..n {
                if active[other] && adjacent[vertex][other] { neighbors[count] = other; count += 1; }
            }
            width = width.max(count);
            for i in 0..count { for j in i + 1..count {
                let (a, b) = (neighbors[i], neighbors[j]);
                adjacent[a][b] = true; adjacent[b][a] = true;
            } }
            active[vertex] = false;
        }
        if width < best_width { best_width = width; best_order[..n].copy_from_slice(&permutation[..n]); }
        let mut pivot = n as isize - 2;
        while pivot >= 0 && permutation[pivot as usize] >= permutation[pivot as usize + 1] { pivot -= 1; }
        if pivot < 0 { break; }
        let pivot = pivot as usize;
        let mut successor = n - 1;
        while permutation[successor] <= permutation[pivot] { successor -= 1; }
        permutation.swap(pivot, successor);
        permutation[pivot + 1..n].reverse();
    }
    let bytes = 8 * (n + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    put(&mut staged, 0, best_width as i64);
    for i in 0..n { put(&mut staged, 8 * (i + 1), best_order[i] as i64); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
