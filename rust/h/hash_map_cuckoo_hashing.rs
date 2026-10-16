const MAX_KEYS: usize = 128;
const MAX_CAPACITY: usize = 256;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn h1(key: i32, capacity: i32) -> i32 {
    let r = key % capacity;
    if r < 0 { r + capacity } else { r }
}

fn h2(key: i32, capacity: i32) -> i32 {
    let r = (key / capacity) % capacity;
    if r < 0 { r + capacity } else { r }
}

fn hash_word(mut hash: u64, word: i64) -> u64 {
    for byte in word.to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    hash
}

#[no_mangle]
pub extern "C" fn hash_map_cuckoo_hashing(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_KEYS + 2 { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    let cap64 = a[0];
    let n64 = a[1];
    if !(16..=256).contains(&cap64) || !(0..=MAX_KEYS as i64).contains(&n64) ||
        (cap64 & (cap64 - 1)) != 0 || length != n64 as usize + 2 { return -1; }
    let cap = cap64 as i32;
    let n = n64 as usize;
    let mut keys = [0i32; MAX_KEYS];
    for i in 0..n {
        let k = a[i + 2];
        if k < i32::MIN as i64 || k > i32::MAX as i64 || k == i32::MIN as i64 { return -1; }
        keys[i] = k as i32;
        if keys[..i].contains(&keys[i]) { return -1; }
    }
    let class_a = n == 2 && h1(keys[0], cap) == h1(keys[1], cap) && h2(keys[0], cap) != h1(keys[0], cap);
    let class_b = (0..n).all(|i| (0..i).all(|j| h1(keys[i], cap) != h1(keys[j], cap)));
    if !class_a && !class_b { return -1; }

    let mut positions = [0i64; MAX_KEYS];
    if class_a {
        let b = h1(keys[0], cap);
        positions[0] = i64::from(h2(keys[0], cap));
        positions[1] = i64::from(b);
    } else {
        let mut final_cap = cap;
        let mut size = 0usize;
        for _ in 0..n {
            if (size + 1) as f64 > f64::from(final_cap) * 0.7 { final_cap *= 2; }
            size += 1;
        }
        for i in 0..n { positions[i] = i64::from(h1(keys[i], final_cap)); }
    }
    let mut hash = hash_word(FNV_OFFSET, n as i64);
    for &position in &positions[..n] { hash = hash_word(hash, position); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
