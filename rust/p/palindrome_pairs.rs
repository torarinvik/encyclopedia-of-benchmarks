const N: usize = 8;
const L: usize = 8;
const H: usize = 17;

fn is_palindrome(words: &[[i32; L]; N], id: usize, left: usize, right: usize) -> bool {
    if right <= left { return true; }
    let mut lo = left;
    let mut hi = right - 1;
    while lo < hi {
        if words[id][lo] != words[id][hi] { return false; }
        lo += 1;
        hi -= 1;
    }
    true
}

fn encode(words: &[[i32; L]; N], id: usize, left: usize, right: usize, reverse: bool) -> i64 {
    let mut key = 1i64;
    if reverse {
        let mut i = right;
        while i > left { i -= 1; key = key * 5 + i64::from(words[id][i] + 1); }
    } else {
        for i in left..right { key = key * 5 + i64::from(words[id][i] + 1); }
    }
    key
}

fn find_slot(keys: &[i64; H], key: i64) -> usize {
    let mut slot = (key as usize) % H;
    while keys[slot] != 0 && keys[slot] != key { slot = (slot + 1) % H; }
    slot
}

fn mark(keys: &[i64; H], heads: &[i32; H], next: &[i32; N], key: i64,
        fixed: usize, fixed_right: bool, found: &mut [[bool; N]; N]) {
    let slot = find_slot(keys, key);
    if keys[slot] != key { return; }
    let mut id = heads[slot];
    while id >= 0 {
        let word = id as usize;
        if word != fixed {
            if fixed_right { found[word][fixed] = true; }
            else { found[fixed][word] = true; }
        }
        id = next[word];
    }
}

#[no_mangle]
pub unsafe extern "C" fn palindrome_pairs(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=74).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=N as i64).contains(&values[0]) { return -1; }
    let count = values[0] as usize;
    let mut words = [[0i32; L]; N];
    let mut sizes = [0usize; N];
    let mut cursor = 1usize;
    for id in 0..count {
        if cursor >= length || !(0..=L as i64).contains(&values[cursor]) { return -1; }
        let size = values[cursor] as usize;
        cursor += 1;
        if cursor + size > length { return -1; }
        sizes[id] = size;
        for k in 0..size {
            if !(0..4).contains(&values[cursor]) { return -1; }
            words[id][k] = values[cursor] as i32;
            cursor += 1;
        }
    }
    if cursor != length { return -1; }
    let mut keys = [0i64; H];
    let mut heads = [-1i32; H];
    let mut next = [-1i32; N];
    for id in 0..count {
        let key = encode(&words, id, 0, sizes[id], false);
        let slot = find_slot(&keys, key);
        if keys[slot] == 0 { keys[slot] = key; heads[slot] = id as i32; }
        else { next[id] = heads[slot]; heads[slot] = id as i32; }
    }
    let mut found = [[false; N]; N];
    for id in 0..count {
        for split in 0..=sizes[id] {
            if is_palindrome(&words, id, 0, split) {
                mark(&keys, &heads, &next, encode(&words, id, split, sizes[id], true), id, true, &mut found);
            }
            if is_palindrome(&words, id, split, sizes[id]) {
                mark(&keys, &heads, &next, encode(&words, id, 0, split, true), id, false, &mut found);
            }
        }
    }
    let mut staged = [0u8; N * (N - 1)];
    let mut bytes = 0usize;
    for left in 0..count { for right in 0..count {
        if left != right && found[left][right] { staged[bytes] = (left * N + right) as u8; bytes += 1; }
    }}
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..bytes { *output.add(i) = staged[i]; }
    bytes as i64
}
