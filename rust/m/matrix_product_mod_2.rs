const MAX_DIMENSION: usize = 64;
const MAX_INPUT_VALUES: usize = 3 + 2 * MAX_DIMENSION * MAX_DIMENSION;
const MAX_OUTPUT_VALUES: usize = MAX_DIMENSION * MAX_DIMENSION;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn matrix_product_mod_2(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    let m_value = *input.add(1);
    let k_value = *input.add(2);
    if !(1..=MAX_DIMENSION as i64).contains(&n_value)
        || !(1..=MAX_DIMENSION as i64).contains(&m_value)
        || !(1..=MAX_DIMENSION as i64).contains(&k_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    let k = k_value as usize;
    let a_length = n * m;
    let b_length = m * k;
    if length != 3 + a_length + b_length {
        return -1;
    }

    let b_start = 3 + a_length;
    let mut packed_b = [0u64; MAX_DIMENSION];
    for inner in 0..m {
        for column in 0..k {
            let bit = *input.add(b_start + inner * k + column);
            if bit != 0 && bit != 1 {
                return -1;
            }
            packed_b[inner] |= (bit as u64) << column;
        }
    }

    let mut staged = [0i64; MAX_OUTPUT_VALUES];
    for row in 0..n {
        let mut accumulator = 0u64;
        for inner in 0..m {
            let bit = *input.add(3 + row * m + inner);
            if bit != 0 && bit != 1 {
                return -1;
            }
            if bit == 1 {
                accumulator ^= packed_b[inner];
            }
        }
        for column in 0..k {
            staged[row * k + column] = ((accumulator >> column) & 1) as i64;
        }
    }

    let required = 8 * n * k;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..n * k {
        store_i64_le(output, 8 * index, staged[index]);
    }
    required as i64
}
