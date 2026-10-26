// Clean-room bounded GBBS MPX low-diameter decomposition profile.
const N: usize = 12;
const M: usize = 24;
const INPUT: usize = 2 + 2 * M;
const BATCH: [usize; 13] = [1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11];

#[no_mangle]
pub unsafe extern "C" fn gbbs_low_diameter_decomposition(input: *const i64,
        length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > N as i64 || m64 < 0 || m64 > M as i64
        || length != 2 + 2 * m64 as usize { return -1; }
    let (n, m) = (n64 as usize, m64 as usize);
    let mut adjacent = [[false; N]; N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 { return -1; }
        let (u, v) = (u64 as usize, v64 as usize);
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    if output.is_null() || capacity < n { return -2; }

    let mut labels = [-1i16; N];
    let mut frontier = [0usize; N];
    let (mut frontier_count, mut cursor, mut assigned, mut round) = (0usize, 0usize, 0usize, 0usize);
    while assigned < n {
        let end = (cursor + BATCH[round]).min(n);
        for candidate in cursor..end {
            if labels[candidate] < 0 {
                labels[candidate] = candidate as i16;
                frontier[frontier_count] = candidate;
                frontier_count += 1;
                assigned += 1;
            }
        }
        cursor = end;
        if assigned == n { break; }

        let mut reached = [-1i16; N];
        for &vertex in &frontier[..frontier_count] {
            for neighbor in 0..n {
                if adjacent[vertex][neighbor] && labels[neighbor] < 0
                    && (reached[neighbor] < 0 || labels[vertex] < reached[neighbor]) {
                    reached[neighbor] = labels[vertex];
                }
            }
        }
        frontier_count = 0;
        for vertex in 0..n {
            if reached[vertex] >= 0 {
                labels[vertex] = reached[vertex];
                frontier[frontier_count] = vertex;
                frontier_count += 1;
                assigned += 1;
            }
        }
        round += 1;
    }
    for vertex in 0..n { *output.add(vertex) = labels[vertex] as u8; }
    n as i64
}
