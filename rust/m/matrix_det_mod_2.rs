const MAX_N: usize = 64;
const MAX_INPUT_VALUES: usize = 1 + MAX_N * MAX_N;

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn matrix_det_mod_2(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    if !(1..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + n * n {
        return -1;
    }

    let mut rows = [0u64; MAX_N];
    for row in 0..n {
        for column in 0..n {
            let bit = *input.add(1 + row * n + column);
            if bit != 0 && bit != 1 {
                return -1;
            }
            rows[row] |= (bit as u64) << column;
        }
    }

    let mut pivot_row = 0;
    for column in 0..n {
        let mut pivot = pivot_row;
        while pivot < n && ((rows[pivot] >> column) & 1) == 0 {
            pivot += 1;
        }
        if pivot == n {
            continue;
        }
        rows.swap(pivot_row, pivot);
        for row in pivot_row + 1..n {
            if ((rows[row] >> column) & 1) != 0 {
                rows[row] ^= rows[pivot_row];
            }
        }
        pivot_row += 1;
    }

    if output.is_null() || capacity < 8 {
        return -2;
    }
    store_i64_le(output, (pivot_row == n) as i64);
    8
}
