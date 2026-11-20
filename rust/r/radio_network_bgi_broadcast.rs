const MAX_N: usize = 8;
const MAX_INPUT: usize = 203;
const MAX_OUTPUT: usize = 88;

unsafe fn put64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

fn ceil_log2(value: usize) -> usize {
    let mut exponent = 0;
    let mut power = 1;
    while power < value { power <<= 1; exponent += 1; }
    exponent
}

#[no_mangle]
pub unsafe extern "C" fn radio_network_bgi_broadcast(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64 = *input; let source64 = *input.add(1); let delta64 = *input.add(2);
    if n64 < 2 || n64 > MAX_N as i64 || source64 < 0 || source64 >= n64 || delta64 < 2 || delta64 > 8 { return -1; }
    let n = n64 as usize; let source = source64 as usize; let delta = delta64 as usize;
    let k = 2 * ceil_log2(delta); let t = ceil_log2(2 * n); let tape_at = 3 + n; let tape_count = n * t * k;
    if length != tape_at + tape_count { return -1; }
    let full = (1_u64 << n) - 1;
    let mut adjacency = [0_u64; MAX_N];
    for v in 0..n {
        let raw = *input.add(3 + v);
        if raw < 0 || (raw as u64) & !full != 0 || (raw as u64) & (1_u64 << v) != 0 { return -1; }
        adjacency[v] = raw as u64;
        if adjacency[v].count_ones() as usize > delta { return -1; }
    }
    for u in 0..n { for v in 0..n { if (adjacency[u] >> v) & 1 != (adjacency[v] >> u) & 1 { return -1; } } }
    for i in 0..tape_count { let bit = *input.add(tape_at + i); if bit != 0 && bit != 1 { return -1; } }
    let output_bytes = 8 * (n + 3);
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut informed = [false; MAX_N]; let mut active = [false; MAX_N]; let mut newly = [false; MAX_N];
    let mut calls = [0_usize; MAX_N]; let mut first_slot = [-1_i64; MAX_N];
    informed[source] = true; first_slot[source] = 0;
    let mut transmissions = 0_i64; let mut phases = 0_i64;
    for phase in 0..(n * t) {
        let mut starters = 0;
        for v in 0..n { active[v] = informed[v] && calls[v] < t; newly[v] = false; if active[v] { starters += 1; } }
        if starters == 0 { break; }
        for slot in 0..k {
            for sender in 0..n { if active[sender] { transmissions += 1; } }
            for receiver in 0..n {
                if informed[receiver] || newly[receiver] { continue; }
                let mut senders = 0;
                for sender in 0..n { if active[sender] && (adjacency[sender] >> receiver) & 1 != 0 { senders += 1; } }
                if senders == 1 { newly[receiver] = true; first_slot[receiver] = (phase * k + slot) as i64; }
            }
            for sender in 0..n { if active[sender] {
                let at = tape_at + (sender * t + calls[sender]) * k + slot;
                if slot + 1 == k || *input.add(at) == 0 { active[sender] = false; }
            } }
        }
        for v in 0..n {
            if informed[v] && calls[v] < t { calls[v] += 1; }
            if newly[v] { informed[v] = true; }
        }
        phases = phase as i64 + 1;
    }
    let mut staged = [0_u8; MAX_OUTPUT];
    put64(staged.as_mut_ptr(), 0, n64); put64(staged.as_mut_ptr(), 8, phases); put64(staged.as_mut_ptr(), 16, transmissions);
    for v in 0..n { put64(staged.as_mut_ptr(), 24 + 8 * v, first_slot[v]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
