// Clean-room negative-cycle detection and witness extraction.
use core::ptr;

const MAX_N: usize = 20;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 2 + 3 * MAX_M;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { ptr::write(output.add(offset + byte), (bits >> (8 * byte)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn negative_cycle_detection(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 0 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64 || length != 2 + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut from = [0usize; MAX_M];
    let mut to = [0usize; MAX_M];
    let mut weight = [0i64; MAX_M];
    for edge in 0..m {
        let u = *input.add(2 + 3 * edge);
        let v = *input.add(3 + 3 * edge);
        let w = *input.add(4 + 3 * edge);
        if u < 0 || u >= n64 || v < 0 || v >= n64 || !(-1000..=1000).contains(&w) { return -1; }
        from[edge] = u as usize; to[edge] = v as usize; weight[edge] = w;
    }
    let mut distance = [0i64; MAX_N];
    let mut predecessor = [-1i64; MAX_N];
    let mut changed_vertex = -1i64;
    for _pass in 0..n {
        changed_vertex = -1;
        for edge in 0..m {
            let u = from[edge]; let v = to[edge];
            let candidate = distance[u] + weight[edge];
            if candidate < distance[v] { distance[v] = candidate; predecessor[v] = u as i64; changed_vertex = v as i64; }
        }
        if changed_vertex < 0 { break; }
    }
    let mut record = [0i64; MAX_N + 2];
    let mut record_length = 1usize;
    if changed_vertex >= 0 {
        let mut vertex = changed_vertex as usize;
        for _ in 0..n {
            if predecessor[vertex] < 0 { return -1; }
            vertex = predecessor[vertex] as usize;
        }
        let start = vertex;
        let mut cycle = [0usize; MAX_N];
        let mut cycle_length = 0usize;
        loop {
            if cycle_length >= n || predecessor[vertex] < 0 { return -1; }
            cycle[cycle_length] = vertex; cycle_length += 1;
            vertex = predecessor[vertex] as usize;
            if vertex == start { break; }
        }
        cycle[..cycle_length].reverse();
        let mut minimum = 0usize;
        for i in 1..cycle_length { if cycle[i] < cycle[minimum] { minimum = i; } }
        record[0] = 1; record[1] = cycle_length as i64;
        for i in 0..cycle_length { record[2+i] = cycle[(minimum+i)%cycle_length] as i64; }
        record_length = cycle_length + 2;
    } else { record[0] = 0; }
    let output_length = 8 * record_length;
    if output.is_null() || capacity < output_length { return -2; }
    for i in 0..record_length { store_i64_le(output, 8*i, record[i]); }
    output_length as i64
}
