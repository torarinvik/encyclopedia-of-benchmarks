const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 4 * MAX_Q;
const HASH_MULTIPLIER: i64 = 1_000_003;
const HASH_MODULUS: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn two_pset(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let qv = packed[0];
    if !(0..=MAX_Q as i64).contains(&qv) || length != 1 + qv as usize * 4 { return -1; }
    let q = qv as usize;
    for i in 0..q {
        let op = packed[1 + i * 4];
        let set_id = packed[2 + i * 4];
        let value = packed[3 + i * 4];
        let other_id = packed[4 + i * 4];
        if (0..=2).contains(&op) {
            if !(0..=1).contains(&set_id) || !(0..=63).contains(&value) || other_id != 0 { return -1; }
        } else if op == 3 || op == 4 {
            if !(0..=1).contains(&set_id) || value != 0 || !(0..=1).contains(&other_id) { return -1; }
        } else { return -1; }
    }

    let mut additions = [0i64; 128];
    let mut tombstones = [0i64; 128];
    let mut digest = 0i64;
    for i in 0..q {
        let op = packed[1 + i * 4];
        let set_id = packed[2 + i * 4] as usize;
        let value = packed[3 + i * 4];
        let other_id = packed[4 + i * 4] as usize;
        let base = set_id * 64;
        let mut operation_result = 0i64;
        if op == 0 {
            additions[base + value as usize] = 1;
        } else if op == 1 {
            let index = base + value as usize;
            if additions[index] != 0 && tombstones[index] == 0 { tombstones[index] = 1; }
        } else if op == 2 {
            let index = base + value as usize;
            if additions[index] != 0 && tombstones[index] == 0 { operation_result = 1; }
        } else if op == 3 {
            let other_base = other_id * 64;
            let mut subset = true;
            for e in 0..64 {
                if (additions[base + e] != 0 && additions[other_base + e] == 0) ||
                   (tombstones[base + e] != 0 && tombstones[other_base + e] == 0) { subset = false; }
            }
            if subset { operation_result = 1; }
        } else {
            let other_base = other_id * 64;
            for e in 0..64 {
                if additions[base + e] != 0 || additions[other_base + e] != 0 { additions[base + e] = 1; }
                if tombstones[base + e] != 0 || tombstones[other_base + e] != 0 { tombstones[base + e] = 1; }
            }
        }
        digest = (digest * HASH_MULTIPLIER + op) % HASH_MODULUS;
        digest = (digest * HASH_MULTIPLIER + operation_result) % HASH_MODULUS;
    }

    for set_id in 0..2 {
        let base = set_id * 64;
        for e in 0..64 { digest = (digest * HASH_MULTIPLIER + additions[base + e]) % HASH_MODULUS; }
        for e in 0..64 { digest = (digest * HASH_MULTIPLIER + tombstones[base + e]) % HASH_MODULUS; }
    }
    digest
}
