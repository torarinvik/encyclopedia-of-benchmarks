const MAX_N: usize = 64;
const MIN_VALUE: i64 = -1_000_000_000;
const MAX_VALUE: i64 = 1_000_000_000;

#[no_mangle]
pub unsafe extern "C" fn minimum_unfairness_k_selection(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || !(4..=MAX_N + 2).contains(&length) {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(packed, length) };
    let n_value = input[0];
    let k_value = input[1];
    if !(2..=MAX_N as i64).contains(&n_value)
        || k_value < 2
        || k_value > n_value
        || length != n_value as usize + 2
    {
        return -1;
    }

    let n = n_value as usize;
    let k = k_value as usize;
    let mut sorted = [0_i64; MAX_N];
    for index in 0..n {
        let value = input[index + 2];
        if !(MIN_VALUE..=MAX_VALUE).contains(&value) {
            return -1;
        }
        sorted[index] = value;
    }
    sorted[..n].sort_unstable();

    let mut best = 2_000_000_001_i64;
    for first in 0..=(n - k) {
        let width = sorted[first + k - 1] - sorted[first];
        if width < best {
            best = width;
        }
    }
    best
}
