const MAX_OPS: usize = 256;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn hash_i64(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    hash
}

#[no_mangle]
pub extern "C" fn immutable_hash_map(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 1 + 3 * MAX_OPS { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    let count64 = a[0];
    if count64 < 0 || count64 > MAX_OPS as i64 || length != 1 + 3 * count64 as usize { return -1; }
    let count = count64 as usize;
    let mut keys = [0i32; MAX_OPS];
    let mut values = [0i32; MAX_OPS];
    let mut trace = [0i64; MAX_OPS];
    let mut map_size = 0usize;

    for i in 0..count {
        let operation = a[1 + 3 * i];
        let key64 = a[2 + 3 * i];
        let value64 = a[3 + 3 * i];
        if !(0..=3).contains(&operation) || key64 < i32::MIN as i64 || key64 > i32::MAX as i64 || value64 < i32::MIN as i64 || value64 > i32::MAX as i64 { return -1; }
        let key = key64 as i32;
        let value = value64 as i32;
        match operation {
            0 => {
                if value == 0 { return -1; }
                keys[map_size] = key;
                values[map_size] = value;
                map_size += 1;
                trace[i] = map_size as i64;
            }
            1 | 2 => {
                let mut found_value = 0i32;
                for j in (0..map_size).rev() {
                    if keys[j] == key { found_value = values[j]; break; }
                }
                trace[i] = if operation == 1 { i64::from(found_value) } else { i64::from(found_value != 0) };
            }
            _ => trace[i] = map_size as i64,
        }
    }

    let mut hash = hash_i64(FNV_OFFSET, count as i64);
    for &word in &trace[..count] { hash = hash_i64(hash, word); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
