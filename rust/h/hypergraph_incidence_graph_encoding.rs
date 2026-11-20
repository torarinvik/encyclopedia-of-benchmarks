const MAX_N: usize = 8;
const MAX_M: usize = 12;
const MAX_INPUT: usize = 111;

unsafe fn put(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn hypergraph_incidence_graph_encoding(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=8).contains(&n64) || !(0..=12).contains(&m64) { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut incidence = [[false; MAX_M]; MAX_N];
    let mut offset = 2usize;
    for edge in 0..m {
        if offset >= length { return -1; }
        let size = *input.add(offset);
        offset += 1;
        if size < 0 || size > n64 || size as usize > length - offset { return -1; }
        for _ in 0..size {
            let vertex64 = *input.add(offset);
            offset += 1;
            if vertex64 < 0 || vertex64 >= n64 { return -1; }
            let vertex = vertex64 as usize;
            if incidence[vertex][edge] { return -1; }
            incidence[vertex][edge] = true;
        }
    }
    if offset != length { return -1; }

    let mut count = 0usize;
    for vertex in 0..n {
        for edge in 0..m {
            if incidence[vertex][edge] { count += 1; }
        }
    }
    let nodes = n + m;
    let bytes = 8 * (2 + nodes + 2 * count);
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, nodes as i64);
    put(output, 8, count as i64);
    let mut word = 2usize;
    for _ in 0..n { put(output, 8 * word, 0); word += 1; }
    for _ in 0..m { put(output, 8 * word, 1); word += 1; }
    for vertex in 0..n {
        for edge in 0..m {
            if incidence[vertex][edge] {
                put(output, 8 * word, vertex as i64); word += 1;
                put(output, 8 * word, (n + edge) as i64); word += 1;
            }
        }
    }
    bytes as i64
}
