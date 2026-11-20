const MAX_N: usize = 128;
const MAX_K: usize = 512;
const MODULUS: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn k_inverse_pairs_array(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 3 || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_N as i64
        || values[1] < 0 || values[1] > MAX_K as i64 { return -1; }
    let n = values[0] as usize;
    let k = values[1] as usize;
    let maximum_inversions = if n == 0 { 0 } else { n * (n - 1) / 2 };
    if k > maximum_inversions { return 0; }

    let mut previous = [0_i64; MAX_K + 1];
    let mut current = [0_i64; MAX_K + 1];
    previous[0] = 1;
    for size in 1..=n {
        let mut window = 0_i64;
        for inversions in 0..=k {
            window += previous[inversions];
            if inversions >= size { window -= previous[inversions - size]; }
            window = window.rem_euclid(MODULUS);
            current[inversions] = window;
        }
        std::mem::swap(&mut previous, &mut current);
        current.fill(0);
    }
    previous[k]
}
