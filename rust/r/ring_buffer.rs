const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_Q;
const VALUE_LIMIT: i64 = 1_000_000;
const VALUE_OFFSET: i64 = 1_000_001;
const HASH_MULTIPLIER: i64 = 1_000_003;
const HASH_MODULUS: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn ring_buffer(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let qv = packed[0];
    if !(0..=MAX_Q as i64).contains(&qv) || length != 1 + qv as usize * 2 { return -1; }
    let q = qv as usize;
    for i in 0..q {
        let (op, payload) = (packed[1 + i * 2], packed[2 + i * 2]);
        if op == 0 { if !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&payload) { return -1; } }
        else if op == 4 { if !(0..=VALUE_LIMIT).contains(&payload) { return -1; } }
        else if (1..=3).contains(&op) || (5..=9).contains(&op) { if payload != 0 { return -1; } }
        else { return -1; }
    }

    let mut values = [0i64; 8];
    let (mut head, mut tail, mut count) = (0usize, 0usize, 0usize);
    let mut hash = 0i64;
    for i in 0..q {
        let (op, payload) = (packed[1 + i * 2], packed[2 + i * 2]);
        let (mut status, mut result) = (0i64, 0i64);
        if op == 0 {
            if count == 8 { status = 1; }
            else { values[tail] = payload; tail = (tail + 1) % 8; count += 1; }
        } else if op == 1 {
            if count == 0 { status = 2; }
            else { result = values[head]; head = (head + 1) % 8; count -= 1; }
        } else if op == 2 {
            if count == 0 { status = 2; } else { result = values[head]; }
        } else if op == 3 {
            if count == 0 { status = 2; } else { result = values[(tail + 7) % 8]; }
        } else if op == 4 {
            if payload >= count as i64 { status = 3; }
            else { result = values[(head + payload as usize) % 8]; }
        } else if op == 5 {
            head = 0; tail = 0; count = 0;
        } else if op == 6 { result = count as i64; }
        else if op == 7 { result = 8 - count as i64; }
        else if op == 8 { if count == 0 { result = 1; } }
        else { if count == 8 { result = 1; } }

        hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + status) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + result + VALUE_OFFSET) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + count as i64) % HASH_MODULUS;
        for j in 0..count {
            let position = (head + j) % 8;
            hash = (hash * HASH_MULTIPLIER + values[position] + VALUE_OFFSET) % HASH_MODULUS;
        }
    }
    hash
}
