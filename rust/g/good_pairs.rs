const MAX_N: usize = 256;
const VALUE_LIMIT: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn good_pairs(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length == 0 || length > MAX_N + 1 { return -1; }
    let n = *packed;
    if n < 0 || n as usize > MAX_N || length != n as usize + 1 { return -1; }
    let values = std::slice::from_raw_parts(packed.add(1), n as usize);
    if values.iter().any(|&value| !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value)) { return -1; }
    let mut count = 0i64;
    for i in 0..values.len() {
        for j in i + 1..values.len() {
            if values[i] == values[j] { count += 1; }
        }
    }
    count
}
