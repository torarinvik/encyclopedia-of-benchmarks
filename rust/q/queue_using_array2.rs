const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_Q;
const VALUE_LIMIT: i64 = 1_000_000;
const VALUE_OFFSET: i64 = 1_000_001;
const HASH_MULTIPLIER: i64 = 1_000_003;
const HASH_MODULUS: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn queue_using_array2(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let qv = packed[0];
    if !(0..=MAX_Q as i64).contains(&qv) || length != 1 + qv as usize * 2 { return -1; }
    let q = qv as usize;
    for i in 0..q {
        let (op, value) = (packed[1 + i * 2], packed[2 + i * 2]);
        if op == 1 { if !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value) { return -1; } }
        else if op == 2 || op == 3 { if value != 0 { return -1; } }
        else { return -1; }
    }

    let mut values = [0i64; 10];
    let mut count = 0usize;
    let mut hash = 0i64;
    for i in 0..q {
        let (op, value) = (packed[1 + i * 2], packed[2 + i * 2]);
        if op == 1 {
            if count < 10 { values[count] = value; count += 1; }
        } else if op == 2 && count > 0 {
            for j in 1..count { values[j - 1] = values[j]; }
            count -= 1;
        }

        hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + count as i64) % HASH_MODULUS;
        for j in 0..count {
            hash = (hash * HASH_MULTIPLIER + values[j] + VALUE_OFFSET) % HASH_MODULUS;
        }
    }
    hash
}
