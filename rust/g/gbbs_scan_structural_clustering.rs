// Clean-room bounded GBBS SCAN profile; see package LICENSE.txt.
const MAX_N: usize = 16;
const MAX_M: usize = 64;

fn similarity_parts(
    u: usize, v: usize, adjacent: &[[bool; MAX_N]; MAX_N], degree: &[usize; MAX_N],
) -> (u64, u64) {
    let mut shared = 0u64;
    for w in 0..MAX_N {
        if adjacent[u][w] && adjacent[v][w] { shared += 1; }
    }
    ((shared + 2), ((degree[u] + 1) * (degree[v] + 1)) as u64)
}
fn epsilon_similar(numerator: u64, denominator_sq: u64) -> bool {
    4 * numerator * numerator >= denominator_sq
}
unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn gbbs_scan_structural_clustering(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_M { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64 { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != 2 + 2 * m { return -1; }
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    if output.is_null() || capacity < 8 * n { return -2; }

    let mut core = [false; MAX_N];
    let mut labels = [-1i64; MAX_N];
    for u in 0..n {
        let mut count = 0;
        for v in 0..n {
            if adjacent[u][v] {
                let (num, den) = similarity_parts(u, v, &adjacent, &degree);
                if epsilon_similar(num, den) { count += 1; }
            }
        }
        core[u] = count >= 2;
    }
    for root in 0..n {
        if !core[root] || labels[root] != -1 { continue; }
        let mut queue = [0usize; MAX_N];
        let mut head = 0usize;
        let mut tail = 0usize;
        labels[root] = root as i64;
        queue[tail] = root;
        tail += 1;
        while head < tail {
            let u = queue[head];
            head += 1;
            for v in 0..n {
                if !core[v] || labels[v] != -1 || !adjacent[u][v] { continue; }
                let (num, den) = similarity_parts(u, v, &adjacent, &degree);
                if epsilon_similar(num, den) {
                    labels[v] = root as i64;
                    queue[tail] = v;
                    tail += 1;
                }
            }
        }
    }
    for u in 0..n {
        if core[u] { continue; }
        let mut best_core = MAX_N;
        let mut best_num = 0u64;
        let mut best_den = 1u64;
        for v in 0..n {
            if !core[v] || !adjacent[u][v] { continue; }
            let (num, den) = similarity_parts(u, v, &adjacent, &degree);
            if !epsilon_similar(num, den) { continue; }
            let left = num * num * best_den;
            let right = best_num * best_num * den;
            if best_core == MAX_N || left > right || (left == right && v < best_core) {
                best_core = v;
                best_num = num;
                best_den = den;
            }
        }
        if best_core != MAX_N { labels[u] = labels[best_core]; }
    }
    for v in 0..n { store_i64_le(output, 8 * v, labels[v]); }
    (8 * n) as i64
}
