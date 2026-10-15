const MAX_N: usize = 256;
const HASH_CAPACITY: usize = 512;

fn hash_slot(value: i32) -> usize {
    let mixed = (value as u32 as u64) * 2_654_435_761u64;
    ((mixed as u32) >> 23) as usize
}

fn find_slot(keys: &[i32; HASH_CAPACITY], occupied: &[bool; HASH_CAPACITY], value: i32) -> usize {
    let mut slot = hash_slot(value);
    for _ in 0..HASH_CAPACITY {
        if !occupied[slot] || keys[slot] == value { return slot; }
        slot = (slot + 1) % HASH_CAPACITY;
    }
    0
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn count_distinct_elements_in_window(input: *const i64, length: usize,
                                                              output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_N as i64).contains(&packed[0]) || packed[1] < 1 || packed[1] > packed[0]
        || length != packed[0] as usize + 2 { return -1; }
    let n = packed[0] as usize;
    let k = packed[1] as usize;
    let out_n = n - k + 1;
    if packed[2..].iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) { return -1; }
    if output.is_null() || capacity < out_n * 8 { return -2; }
    let out = std::slice::from_raw_parts_mut(output, out_n * 8);
    let mut keys = [0i32; HASH_CAPACITY];
    let mut counts = [0i32; HASH_CAPACITY];
    let mut occupied = [false; HASH_CAPACITY];
    let mut distinct = 0i64;
    for i in 0..k {
        let value = packed[i + 2] as i32;
        let slot = find_slot(&keys, &occupied, value);
        if !occupied[slot] { keys[slot] = value; occupied[slot] = true; counts[slot] = 0; }
        if counts[slot] == 0 { distinct += 1; }
        counts[slot] += 1;
    }
    put_i64_le(out, 0, distinct);
    for i in k..n {
        let incoming = packed[i + 2] as i32;
        let slot = find_slot(&keys, &occupied, incoming);
        if !occupied[slot] { keys[slot] = incoming; occupied[slot] = true; counts[slot] = 0; }
        if counts[slot] == 0 { distinct += 1; }
        counts[slot] += 1;
        let outgoing = packed[i - k + 2] as i32;
        let slot = find_slot(&keys, &occupied, outgoing);
        counts[slot] -= 1;
        if counts[slot] == 0 { distinct -= 1; }
        put_i64_le(out, (i - k + 1) * 8, distinct);
    }
    (out_n * 8) as i64
}
