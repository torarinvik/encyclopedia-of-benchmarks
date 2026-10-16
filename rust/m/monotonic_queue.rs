const MAX_N: usize = 4096;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn hash_i32(mut hash: u64, value: i64) -> u64 {
    for byte in (value as i32).to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    hash
}

#[no_mangle]
pub extern "C" fn monotonic_queue(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_N + 2 { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    let n64 = a[0]; let window64 = a[1];
    if n64 < 1 || n64 > MAX_N as i64 || window64 < 1 || window64 > n64 || length != n64 as usize + 2 { return -1; }
    let n = n64 as usize; let window = window64 as usize;
    if a[2..].iter().any(|&x| x < i32::MIN as i64 || x > i32::MAX as i64) { return -1; }
    let mut deque = [0usize; MAX_N]; let mut head = 0usize; let mut tail = 0usize;
    let mut hash = FNV_OFFSET;
    for i in 0..n {
        while head < tail && deque[head] + window <= i { head += 1; }
        while head < tail && a[2 + deque[tail - 1]] <= a[2 + i] { tail -= 1; }
        deque[tail] = i; tail += 1;
        if i + 1 >= window { hash = hash_i32(hash, a[2 + deque[head]]); }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
