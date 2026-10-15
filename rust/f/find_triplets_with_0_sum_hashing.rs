const MAX_ITEMS: usize = 64;
const MAX_TRIPLETS: usize = 2048;
const HASH_CAPACITY: usize = 128;
const BYTES_PER_TRIPLET: usize = 12;

fn hash_slot(value: i64) -> usize { (((value + 100_000) * 37) % HASH_CAPACITY as i64) as usize }

fn seen_contains(keys: &[i64; HASH_CAPACITY], occupied: &[bool; HASH_CAPACITY], value: i64) -> bool {
    let mut slot = hash_slot(value);
    for _ in 0..HASH_CAPACITY {
        if !occupied[slot] { return false; }
        if keys[slot] == value { return true; }
        slot = (slot + 1) % HASH_CAPACITY;
    }
    false
}

fn seen_add(keys: &mut [i64; HASH_CAPACITY], occupied: &mut [bool; HASH_CAPACITY], value: i64) {
    let mut slot = hash_slot(value);
    for _ in 0..HASH_CAPACITY {
        if !occupied[slot] { keys[slot] = value; occupied[slot] = true; return; }
        if keys[slot] == value { return; }
        slot = (slot + 1) % HASH_CAPACITY;
    }
}

fn sort3(mut a: i64, mut b: i64, mut c: i64) -> (i64, i64, i64) {
    if a > b { std::mem::swap(&mut a, &mut b); }
    if b > c { std::mem::swap(&mut b, &mut c); }
    if a > b { std::mem::swap(&mut a, &mut b); }
    (a, b, c)
}

fn already_output(triples: &[i64; MAX_TRIPLETS * 3], count: usize, a: i64, b: i64, c: i64) -> bool {
    (0..count).any(|i| triples[i * 3] == a && triples[i * 3 + 1] == b && triples[i * 3 + 2] == c)
}

fn write_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as i32 as u32;
    for byte in 0..4 { unsafe { output.add(offset + byte).write((bits >> (byte * 8)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn find_triplets_with_0_sum_hashing(input: *const i64, length: usize,
                                                            output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_ITEMS || (length > 0 && input.is_null()) { return -1; }
    for i in 0..length { let value = *input.add(i); if !(-100_000..=100_000).contains(&value) { return -1; } }
    let mut triples = [0i64; MAX_TRIPLETS * 3];
    let mut count = 0usize;
    for i in 0..length {
        if i + 2 >= length { break; }
        let mut keys = [0i64; HASH_CAPACITY];
        let mut occupied = [false; HASH_CAPACITY];
        for j in i + 1..length {
            let other = *input.add(j);
            let required = -*input.add(i) - other;
            if (-100_000..=100_000).contains(&required) && seen_contains(&keys, &occupied, required) {
                let (a, b, c) = sort3(*input.add(i), other, required);
                if !already_output(&triples, count, a, b, c) && count < MAX_TRIPLETS {
                    triples[count * 3] = a; triples[count * 3 + 1] = b; triples[count * 3 + 2] = c;
                    count += 1;
                }
            }
            seen_add(&mut keys, &mut occupied, other);
        }
    }
    if count == 0 { return 0; }
    let needed = count * BYTES_PER_TRIPLET;
    if output.is_null() || output_capacity < needed { return -2; }
    for i in 0..count * 3 { write_i32_le(output, i * 4, triples[i]); }
    count as i64
}
