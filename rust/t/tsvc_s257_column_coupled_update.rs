const MIN_N: usize = 2;
const MAX_N: usize = 8;
const MAX_PASSES: usize = 4;

/// Return the final checksum of the bounded TSVC s257 coupled array update.
#[no_mangle]
pub unsafe extern "C" fn tsvc_s257_column_coupled_update(
    values: *const i64,
    length: usize,
) -> i64 {
    if values.is_null() || length < 12 || length > 2 + MAX_N + 2 * MAX_N * MAX_N {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let n_value = values[0];
    let passes_value = values[1];
    if !(MIN_N as i64..=MAX_N as i64).contains(&n_value)
        || !(1..=MAX_PASSES as i64).contains(&passes_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let passes = passes_value as usize;
    if length != 2 + n + 2 * n * n || values[2..].iter().any(|&x| !(-1..=1).contains(&x)) {
        return -1;
    }

    let mut a = values[2..2 + n].to_vec();
    let aa_start = 2 + n;
    let bb_start = aa_start + n * n;
    let mut aa = values[aa_start..bb_start].to_vec();
    let bb = &values[bb_start..];
    for _ in 0..passes {
        for i in 1..n {
            for j in 0..n {
                let cell = j * n + i;
                a[i] = aa[cell] - a[i - 1];
                aa[cell] = a[i] + bb[cell];
            }
        }
    }
    a.iter().sum::<i64>() + aa.iter().sum::<i64>()
}
