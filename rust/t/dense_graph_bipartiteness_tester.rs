const MAX_N: usize = 64;
const MAX_Q: usize = 16;
const MAX_INPUT: usize = 82;

fn has_edge(row: i64, vertex: usize) -> bool { (((row as u64) >> vertex) & 1) != 0 }
fn put_i64(output: &mut [u8; 16], offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    output[offset..offset + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub extern "C" fn dense_graph_bipartiteness_tester(input: *const i64, length: usize,
                                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=64).contains(&values[0]) || !(1..=16).contains(&values[1]) { return -1; }
    let n = values[0] as usize; let q = values[1] as usize;
    if q > n || length != 2 + n + q { return -1; }
    let rows = &values[2..2 + n]; let draws = &values[2 + n..];
    for i in 0..n {
        if (n < 64 && (rows[i] < 0 || ((rows[i] as u64) >> n) != 0)) || has_edge(rows[i], i) { return -1; }
        for j in i + 1..n { if has_edge(rows[i], j) != has_edge(rows[j], i) { return -1; } }
    }
    let mut remaining = [0usize; MAX_N];
    for i in 0..n { remaining[i] = i; }
    let mut sample = [0usize; MAX_Q];
    for i in 0..q {
        if draws[i] < 0 || draws[i] as u64 >= (n - i) as u64 { return -1; }
        let selected = i + draws[i] as usize;
        remaining.swap(i, selected); sample[i] = remaining[i];
    }
    let mut adjacent = [[false; MAX_Q]; MAX_Q];
    for i in 0..q { for j in i + 1..q { adjacent[i][j] = has_edge(rows[sample[i]], sample[j]); adjacent[j][i] = adjacent[i][j]; } }
    let mut color = [-1i8; MAX_Q]; let mut accepted = 1i64;
    for start in 0..q {
        if color[start] != -1 { continue; }
        let mut queue = [0usize; MAX_Q]; let mut head = 0usize; let mut tail = 0usize;
        queue[tail] = start; tail += 1; color[start] = 0;
        while head < tail {
            let vertex = queue[head]; head += 1;
            for neighbor in 0..q {
                if !adjacent[vertex][neighbor] { continue; }
                if color[neighbor] == -1 { color[neighbor] = color[vertex] ^ 1; queue[tail] = neighbor; tail += 1; }
                else if color[neighbor] == color[vertex] { accepted = 0; }
            }
        }
    }
    if output.is_null() || capacity < 16 { return -2; }
    let mut staged = [0u8; 16]; put_i64(&mut staged, 0, accepted);
    put_i64(&mut staged, 8, (q * (q - 1) / 2) as i64);
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, 16); }
    16
}
