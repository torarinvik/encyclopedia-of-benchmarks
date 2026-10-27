const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const BUCKET: usize = 3;
const MAX_B: usize = 11;
const MAX_WORDS: usize = 100;

fn lcp(a: u16, b: u16) -> i64 {
    let mut count = 0i64;
    while count < 16 && ((a >> (15 - count as u32)) & 1) == ((b >> (15 - count as u32)) & 1) { count += 1; }
    count
}
unsafe fn put_i64(out: *mut u8, pos: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *out.add(pos + b) = (bits >> (8 * b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn mmpfh_bucketing(input: *const i64, length: usize,
                                            output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 66 { return -1; }
    let n0 = *input; let q0 = *input.add(1);
    if n0 < 1 || n0 > MAX_N as i64 || q0 < 1 || q0 > MAX_Q as i64 || length != 2 + n0 as usize + q0 as usize { return -1; }
    let n = n0 as usize; let q = q0 as usize;
    let mut keys = [0u16; MAX_N]; let mut queries = [0u16; MAX_Q];
    for i in 0..n {
        let x = *input.add(2 + i);
        if x < 0 || x > 65535 || (i > 0 && keys[i - 1] >= x as u16) { return -1; }
        keys[i] = x as u16;
    }
    for i in 0..q {
        let x = *input.add(2 + n + i);
        if x < 0 || x > 65535 { return -1; }
        queries[i] = x as u16;
        if !keys[..n].contains(&queries[i]) { return -1; }
    }
    let buckets = (n + BUCKET - 1) / BUCKET;
    let mut d0 = [0i64; MAX_N]; let mut lens = [0i64; MAX_B]; let mut prefixes = [0i64; MAX_B];
    let mut ranks = [0i64; MAX_Q];
    for b in 0..buckets {
        let start = b * BUCKET; let end = core::cmp::min(start + BUCKET, n);
        let plen = if end - start == 1 { 16 } else { lcp(keys[start], keys[end - 1]) };
        let prefix = if plen == 0 { 0 } else { (keys[start] as i64) >> (16 - plen) };
        lens[b] = plen; prefixes[b] = prefix;
        for i in start..end { d0[i] = plen; }
    }
    for i in 0..q {
        let pos = keys[..n].iter().position(|&x| x == queries[i]).unwrap();
        let plen = d0[pos]; let prefix = if plen == 0 { 0 } else { (queries[i] as i64) >> (16 - plen) };
        let mut b = 0;
        while b < buckets && (lens[b] != plen || prefixes[b] != prefix) { b += 1; }
        if b == buckets { return -1; }
        ranks[i] = (b * BUCKET + pos - b * BUCKET) as i64;
    }
    let words = 3 + n + 3 * buckets + q;
    if output.is_null() || capacity < words * 8 { return -2; }
    let mut staged = [0i64; MAX_WORDS]; let mut k = 0;
    staged[k] = n as i64; k += 1; staged[k] = buckets as i64; k += 1; staged[k] = q as i64; k += 1;
    for i in 0..n { staged[k] = d0[i]; k += 1; }
    for b in 0..buckets { staged[k] = lens[b]; k += 1; staged[k] = prefixes[b]; k += 1; staged[k] = b as i64; k += 1; }
    for i in 0..q { staged[k] = ranks[i]; k += 1; }
    for i in 0..words { put_i64(output, i * 8, staged[i]); }
    (words * 8) as i64
}
