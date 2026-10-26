// Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt.
const MAX_N: usize = 12;
const MAX_M: usize = 24;
const MAX_INPUT: usize = 52;
const MAX_CUTOFF: usize = 128;

fn hash64(value: u64) -> u64 {
    let mut mixed = value.wrapping_mul(3_935_559_000_370_003_845)
        .wrapping_add(2_691_343_689_449_507_681);
    mixed ^= mixed >> 21;
    mixed ^= mixed << 37;
    mixed ^= mixed >> 4;
    mixed = mixed.wrapping_mul(4_768_777_513_237_032_717);
    mixed ^= mixed << 20;
    mixed ^= mixed >> 41;
    mixed ^= mixed << 5;
    mixed
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

fn query(vertex: usize, degree: &[usize; MAX_N], neighbors: &[[usize; MAX_N]; MAX_N],
         priority: &[u64; MAX_N], work: &mut usize, cutoff: usize) -> i64 {
    for index in 0..degree[vertex] {
        if *work == cutoff { return -1; }
        let neighbor = neighbors[vertex][index];
        *work += 1;
        if priority[vertex] < priority[neighbor]
            || (priority[vertex] == priority[neighbor] && vertex <= neighbor) { break; }
        let status = query(neighbor, degree, neighbors, priority, work, cutoff);
        if status == 1 { return 0; }
        if status == -1 { return -1; }
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn gbbs_yoshida_query_mis(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let root64 = *input.add(2);
    let cutoff64 = *input.add(3);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || root64 < 0 || root64 >= n64 || !(0..=MAX_CUTOFF as i64).contains(&cutoff64)
        || length != 4 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(4 + 2 * edge);
        let v64 = *input.add(5 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    if output.is_null() || capacity < 16 { return -2; }
    let mut priority = [0u64; MAX_N];
    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    for vertex in 0..n { priority[vertex] = hash64(vertex as u64); }
    for vertex in 0..n {
        let mut inserted = 0usize;
        for other in 0..n {
            if adjacent[vertex][other] {
                let mut position = inserted;
                while position > 0 {
                    let previous = neighbors[vertex][position - 1];
                    if priority[previous] < priority[other]
                        || (priority[previous] == priority[other] && previous < other) { break; }
                    neighbors[vertex][position] = previous;
                    position -= 1;
                }
                neighbors[vertex][position] = other;
                inserted += 1;
            }
        }
    }
    let mut work = 0usize;
    let status = query(root64 as usize, &degree, &neighbors, &priority, &mut work, cutoff64 as usize);
    store_i64_le(output, 0, status);
    store_i64_le(output, 8, work as i64);
    16
}
