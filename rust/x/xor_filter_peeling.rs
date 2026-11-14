#[no_mangle]
pub unsafe extern "C" fn xor_filter_peeling(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=259).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=32).contains(&values[0]) || !(3..=96).contains(&values[1]) || !(0..=32).contains(&values[2]) { return -1; }
    let n = values[0] as usize;
    let slots = values[1] as usize;
    let q = values[2] as usize;
    if length != 3 + 4*(n+q) { return -1; }
    for r in values[3..].chunks_exact(4) {
        if r[..3].iter().any(|&v| v < 0 || v >= slots as i64) || r[0] == r[1] || r[0] == r[2] || r[1] == r[2] || !(0..=255).contains(&r[3]) { return -1; }
    }
    let mut degree = [0_usize; 96];
    let mut edge_xor = [0_usize; 96];
    let mut queue = [0_usize; 96];
    let mut stack = [(0_usize, 0_usize); 32];
    let mut table = [0_i64; 96];
    for edge in 0..n {
        for j in 0..3 {
            let slot = values[3+4*edge+j] as usize;
            degree[slot] += 1;
            edge_xor[slot] ^= edge;
        }
    }
    let (mut head, mut tail, mut used) = (0, 0, 0);
    for slot in 0..slots {
        if degree[slot] == 1 { queue[tail] = slot; tail += 1; }
    }
    while head < tail {
        let slot = queue[head];
        head += 1;
        if degree[slot] != 1 { continue; }
        let edge = edge_xor[slot];
        stack[used] = (slot, edge);
        used += 1;
        for j in 0..3 {
            let v = values[3+4*edge+j] as usize;
            degree[v] -= 1;
            edge_xor[v] ^= edge;
            if degree[v] == 1 { queue[tail] = v; tail += 1; }
        }
    }
    if used != n { return -2; }
    while used > 0 {
        used -= 1;
        let (slot, edge) = stack[used];
        let at = 3+4*edge;
        table[slot] = values[at+3] ^ table[values[at] as usize] ^ table[values[at+1] as usize] ^ table[values[at+2] as usize];
    }
    let mut result = 0_i64;
    for i in 0..q {
        let at = 3+4*(n+i);
        if table[values[at] as usize] ^ table[values[at+1] as usize] ^ table[values[at+2] as usize] == values[at+3] {
            result += (i+1) as i64;
        }
    }
    result
}
