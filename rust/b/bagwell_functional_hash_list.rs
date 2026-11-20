//! Clean-room bounded Bagwell functional hash-list.
use std::slice;

const STARTS: [usize; 3] = [0, 8, 24];
const SIDES: [usize; 3] = [8, 16, 32];
const ABSENT: i64 = i64::MIN;

unsafe fn put_i64_le(output: *mut u8, at: usize, value: i64) {
    for (i, byte) in value.to_le_bytes().iter().enumerate() { output.add(at + i).write(*byte); }
}

#[no_mangle]
pub unsafe extern "C" fn bagwell_functional_hash_list(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=131).contains(&length) { return -1; }
    let words = slice::from_raw_parts(input, length);
    let nv = words[0];
    if !(0..=32).contains(&nv) { return -1; }
    let n = nv as usize;
    let q_at = 1 + 2 * n;
    if q_at >= length { return -1; }
    let qv = words[q_at];
    if !(1..=32).contains(&qv) { return -1; }
    let q = qv as usize;
    let query_at = q_at + 1;
    if length != 2 + 2 * n + 2 * q { return -1; }
    for i in 0..n {
        if !(i32::MIN as i64..=i32::MAX as i64).contains(&words[1 + 2 * i])
            || !(i32::MIN as i64..=i32::MAX as i64).contains(&words[2 + 2 * i]) { return -1; }
    }
    for j in 0..q {
        let root = words[query_at + 2 * j];
        let key = words[query_at + 2 * j + 1];
        if !(0..=nv).contains(&root) || !(i32::MIN as i64..=i32::MAX as i64).contains(&key) { return -1; }
    }
    let bytes = 8 * q;
    if output.is_null() || capacity < bytes { return -2; }

    let mut keys = [0_i64; 56];
    let mut values = [0_i64; 56];
    let mut next = [-1_i32; 56];
    let mut heads = [-1_i32; 56];
    let mut prev = [-1_i32; 3];
    let mut root_block = [-1_i32; 33];
    let mut root_offset = [-1_i32; 33];
    let mut current = 0_usize;
    for i in 0..n {
        if i == 8 || i == 24 { prev[current + 1] = current as i32; current += 1; }
        let offset = i - STARTS[current];
        let slot = STARTS[current] + offset;
        let hash = words[1 + 2 * i] as u32;
        let bucket_slot = STARTS[current] + ((hash as usize) & (SIDES[current] - 1));
        keys[slot] = words[1 + 2 * i];
        values[slot] = words[2 + 2 * i];
        next[slot] = heads[bucket_slot];
        heads[bucket_slot] = offset as i32;
        root_block[i + 1] = current as i32;
        root_offset[i + 1] = offset as i32;
    }
    for j in 0..q {
        let root = words[query_at + 2 * j] as usize;
        let key = words[query_at + 2 * j + 1];
        let mut block = root_block[root];
        let limit = root_offset[root];
        let mut answer = ABSENT;
        if block >= 0 {
            let hash = key as u32;
            let mut first = true;
            while block >= 0 && answer == ABSENT {
                let b = block as usize;
                let bucket = STARTS[b] + ((hash as usize) & (SIDES[b] - 1));
                let mut chain = heads[bucket];
                while chain >= 0 {
                    let slot = STARTS[b] + chain as usize;
                    if (!first || chain <= limit) && keys[slot] == key { answer = values[slot]; break; }
                    chain = next[slot];
                }
                block = prev[b];
                first = false;
            }
        }
        put_i64_le(output, 8 * j, answer);
    }
    bytes as i64
}
