const MAX_N: usize = 32;
const MAX_INPUT: usize = 67;
const MAX_OUTPUT: usize = 16;

fn put_u64(output: &mut [u8], word: usize, value: u64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn psi_suffix_array_access(input: *const i64, length: usize,
                                                    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, query0, stride0) = (values[0], values[1], values[2]);
    if !(1..=MAX_N as i64).contains(&n0) || query0 < 0 || query0 >= n0 || stride0 < 1 || stride0 > n0 ||
       length != 3 + 2 * n0 as usize { return -1; }
    let n = n0 as usize; let query = query0 as usize; let stride = stride0 as usize;
    let mut destinations = [false; MAX_N]; let mut visited = [false; MAX_N];
    for i in 0..n {
        let next = values[3 + i]; let sample = values[3 + n + i];
        if next < 0 || next >= n0 || destinations[next as usize] || sample < 0 || sample > n0 { return -1; }
        destinations[next as usize] = true;
    }
    let mut anchor = n;
    for i in 0..n { if values[3 + n + i] != 0 { anchor = i; break; } }
    if anchor == n { return -1; }
    let anchor_value = values[3 + n + anchor];
    if (anchor_value - 1) % stride0 != 0 { return -1; }
    let mut full_sa = [0u64; MAX_N];
    let mut rank = anchor; let mut value = anchor_value;
    for _ in 0..n {
        if visited[rank] { return -1; }
        visited[rank] = true; full_sa[rank] = value as u64;
        rank = values[3 + rank] as usize;
        value = if value == n0 { 1 } else { value + 1 };
    }
    if rank != anchor || value != anchor_value { return -1; }
    for i in 0..n {
        let expected = if (full_sa[i] - 1) % stride as u64 == 0 { full_sa[i] as i64 } else { 0 };
        if values[3 + n + i] != expected { return -1; }
    }
    rank = query; let mut hops = 0usize;
    while values[3 + n + rank] == 0 {
        rank = values[3 + rank] as usize; hops += 1;
        if hops >= stride { return -1; }
    }
    let mut position0 = values[3 + n + rank] - 1 - hops as i64;
    position0 %= n0; if position0 < 0 { position0 += n0; }
    if output.is_null() || capacity < MAX_OUTPUT { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, MAX_OUTPUT);
    put_u64(dst, 0, (position0 + 1) as u64); put_u64(dst, 1, hops as u64);
    MAX_OUTPUT as i64
}
