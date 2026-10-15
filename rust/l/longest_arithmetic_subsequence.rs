/// Length of the longest arithmetic subsequence.
#[no_mangle]
pub unsafe extern "C" fn longest_arithmetic_subsequence(values: *const i64, length: usize) -> i64 {
    if length > 64 || (length != 0 && values.is_null()) { return -1; }
    if length == 0 { return 0; }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1; }
    if length <= 1 { return length as i64; }
    let mut keys = [[0i64; 127]; 64];
    let mut sizes = [[0i64; 127]; 64];
    let mut maximum = 2i64;
    for right in 0..length {
        for left in 0..right {
            let difference = values[right] - values[left];
            let hash = ((difference % 127 + 127) % 127) as usize;
            let mut slot = hash;
            while sizes[left][slot] != 0 && keys[left][slot] != difference { slot = (slot + 1) % 127; }
            let candidate = if sizes[left][slot] == 0 { 2 } else { sizes[left][slot] + 1 };
            slot = hash;
            while sizes[right][slot] != 0 && keys[right][slot] != difference { slot = (slot + 1) % 127; }
            if sizes[right][slot] == 0 || candidate > sizes[right][slot] {
                keys[right][slot] = difference;
                sizes[right][slot] = candidate;
            }
            maximum = maximum.max(candidate);
        }
    }
    maximum
}
