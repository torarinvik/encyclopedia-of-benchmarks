// Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn gbbs_label_propagation_clustering(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    const MAX_N: usize = 16;
    const MAX_M: usize = 64;
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_M { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64 { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != 2 + 2 * m { return -1; }
    let mut adjacent = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut labels = [0i64; MAX_N];
    for vertex in 0..n { labels[vertex] = vertex as i64; }
    for u in 0..n {
        let mut frequency = [0usize; MAX_N];
        let mut degree = 0usize;
        for v in 0..n {
            if adjacent[u][v] {
                frequency[labels[v] as usize] += 1;
                degree += 1;
            }
        }
        if degree == 0 { continue; }
        let mut best_label = 0usize;
        let mut best_frequency = 0usize;
        for label in 0..n {
            if frequency[label] > best_frequency ||
                (frequency[label] == best_frequency && frequency[label] != 0 && label > best_label) {
                best_label = label;
                best_frequency = frequency[label];
            }
        }
        labels[u] = best_label as i64;
    }
    for vertex in 0..n {
        let bits = labels[vertex] as u64;
        for byte in 0..8 { *output.add(8 * vertex + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
    output_bytes as i64
}
