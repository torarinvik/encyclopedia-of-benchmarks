#[no_mangle]
pub unsafe extern "C" fn myrvold_ruskey_permutation_unrank(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 3 {
        return -1;
    }
    if length != 2 {
        return -1;
    }

    let n_value = unsafe { *input };
    let rank_value = unsafe { *input.add(1) };
    if !(0..=8).contains(&n_value) || rank_value < 0 {
        return -1;
    }
    let n = n_value as usize;
    let mut factorial = 1i64;
    for factor in 2..=n {
        factorial *= factor as i64;
    }
    if rank_value >= factorial {
        return -1;
    }

    let required = 8 * n;
    if output.is_null() || capacity < required {
        return -2;
    }

    let mut permutation = [0i64; 8];
    for (i, slot) in permutation.iter_mut().take(n).enumerate() {
        *slot = i as i64;
    }
    let mut remainder = rank_value;
    let mut size = n;
    while size > 0 {
        let choice = (remainder % size as i64) as usize;
        remainder /= size as i64;
        permutation.swap(size - 1, choice);
        size -= 1;
    }

    for i in 0..n {
        let value = permutation[i] as u64;
        for byte in 0..8 {
            unsafe {
                *output.add(8 * i + byte) = (value >> (8 * byte)) as u8;
            }
        }
    }
    required as i64
}
