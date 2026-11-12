const MAX_N: usize = 32;
const MAX_M: usize = 32;
const MAX_INPUT_VALUES: usize = 2 + MAX_N * MAX_M + MAX_N;

unsafe fn store_u64_le(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 {
        *output.add(offset + byte) = (value >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn system_of_linear_equations_mod_2(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    let m_value = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n_value) || !(1..=MAX_M as i64).contains(&m_value) {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + n * m + n {
        return -1;
    }

    let mut rows = [0u64; MAX_N];
    let mut rhs = [0u8; MAX_N];
    for row in 0..n {
        for column in 0..m {
            let bit = *input.add(2 + row * m + column);
            if bit != 0 && bit != 1 {
                return -1;
            }
            rows[row] |= (bit as u64) << column;
        }
        let bit = *input.add(2 + n * m + row);
        if bit != 0 && bit != 1 {
            return -1;
        }
        rhs[row] = bit as u8;
    }

    let mut pivot_columns = [0usize; MAX_N];
    let mut pivot_row = 0;
    for column in 0..m {
        let mut pivot = pivot_row;
        while pivot < n && ((rows[pivot] >> column) & 1) == 0 {
            pivot += 1;
        }
        if pivot == n {
            continue;
        }
        rows.swap(pivot_row, pivot);
        rhs.swap(pivot_row, pivot);
        for row in 0..n {
            if row != pivot_row && ((rows[row] >> column) & 1) != 0 {
                rows[row] ^= rows[pivot_row];
                rhs[row] ^= rhs[pivot_row];
            }
        }
        pivot_columns[pivot_row] = column;
        pivot_row += 1;
    }

    for row in pivot_row..n {
        if rows[row] == 0 && rhs[row] != 0 {
            if output.is_null() || capacity < 8 {
                return -2;
            }
            store_u64_le(output, 0, u64::MAX);
            return 8;
        }
    }

    let mut is_pivot = [false; MAX_M];
    for row in 0..pivot_row {
        is_pivot[pivot_columns[row]] = true;
    }
    let nullity = m - pivot_row;
    let output_bytes = 8 * (nullity + 2);
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut particular = 0u64;
    for row in 0..pivot_row {
        if rhs[row] != 0 {
            particular |= 1u64 << pivot_columns[row];
        }
    }
    store_u64_le(output, 0, nullity as u64);
    store_u64_le(output, 8, particular);
    let mut basis_index = 0;
    for free_column in 0..m {
        if is_pivot[free_column] {
            continue;
        }
        let mut basis = 1u64 << free_column;
        for row in 0..pivot_row {
            if ((rows[row] >> free_column) & 1) != 0 {
                basis |= 1u64 << pivot_columns[row];
            }
        }
        store_u64_le(output, 16 + 8 * basis_index, basis);
        basis_index += 1;
    }
    output_bytes as i64
}
