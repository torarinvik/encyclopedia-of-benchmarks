const MAX_CASES: usize = 4;
const MAX_VECTORS: usize = 8;
const MAX_BITS: usize = 30;
const MAX_INPUT_VALUES: usize = 1 + MAX_CASES * (2 + 2 * MAX_VECTORS) + 1;
const MAX_OUTPUT_WORDS: usize = MAX_CASES * (1 + MAX_VECTORS);
const MAX_VECTOR: u32 = 0x3fff_ffff;

fn insert_independent(basis: &mut [u32; MAX_BITS], value: u32) -> bool {
    let mut row = value;
    for bit in (0..MAX_BITS).rev() {
        if (row >> bit) & 1 == 0 {
            continue;
        }
        if basis[bit] != 0 {
            row ^= basis[bit];
        } else {
            basis[bit] = row;
            return true;
        }
    }
    false
}

fn intersection_basis(
    left: &[u32; MAX_VECTORS],
    n: usize,
    right: &[u32; MAX_VECTORS],
    m: usize,
    output: &mut [u32; MAX_VECTORS],
) -> usize {
    let mut right_basis = [0u32; MAX_BITS];
    let mut right_coeff = [0u32; MAX_BITS];
    for index in 0..m {
        let mut row = right[index];
        let mut coefficients = 1u32 << index;
        for bit in (0..MAX_BITS).rev() {
            if (row >> bit) & 1 == 0 {
                continue;
            }
            if right_basis[bit] != 0 {
                row ^= right_basis[bit];
                coefficients ^= right_coeff[bit];
            } else {
                right_basis[bit] = row;
                right_coeff[bit] = coefficients;
                break;
            }
        }
    }

    let mut quotient_basis = [0u32; MAX_BITS];
    let mut quotient_left_coeff = [0u32; MAX_BITS];
    let mut quotient_right_coeff = [0u32; MAX_BITS];
    let mut intersection = [0u32; MAX_VECTORS];
    let mut intersection_count = 0;
    for index in 0..n {
        let mut row = left[index];
        let mut right_mask = 0u32;
        for bit in (0..MAX_BITS).rev() {
            if (row >> bit) & 1 != 0 && right_basis[bit] != 0 {
                row ^= right_basis[bit];
                right_mask ^= right_coeff[bit];
            }
        }
        let mut left_mask = 1u32 << index;
        for bit in (0..MAX_BITS).rev() {
            if (row >> bit) & 1 == 0 {
                continue;
            }
            if quotient_basis[bit] != 0 {
                row ^= quotient_basis[bit];
                left_mask ^= quotient_left_coeff[bit];
                right_mask ^= quotient_right_coeff[bit];
            } else {
                quotient_basis[bit] = row;
                quotient_left_coeff[bit] = left_mask;
                quotient_right_coeff[bit] = right_mask;
                break;
            }
        }
        if row == 0 {
            let mut common = 0u32;
            for source in 0..n {
                if (left_mask >> source) & 1 != 0 {
                    common ^= left[source];
                }
            }
            intersection[intersection_count] = common;
            intersection_count += 1;
        }
    }

    let mut rref = [0u32; MAX_BITS];
    for index in 0..intersection_count {
        let mut row = intersection[index];
        for bit in (0..MAX_BITS).rev() {
            if (row >> bit) & 1 == 0 {
                continue;
            }
            if rref[bit] != 0 {
                row ^= rref[bit];
            } else {
                rref[bit] = row;
                for pivot in 0..MAX_BITS {
                    if pivot != bit && (rref[pivot] >> bit) & 1 != 0 {
                        rref[pivot] ^= row;
                    }
                }
                break;
            }
        }
    }
    let mut output_count = 0;
    for bit in (0..MAX_BITS).rev() {
        if rref[bit] != 0 {
            output[output_count] = rref[bit];
            output_count += 1;
        }
    }
    output_count
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn intersection_of_f2_vector_spaces(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let case_count_value = *input;
    if case_count_value < 1 || case_count_value > MAX_CASES as i64 {
        return -1;
    }
    let case_count = case_count_value as usize;
    let mut staged = [0i64; MAX_OUTPUT_WORDS];
    let mut used = 0usize;
    let mut cursor = 1usize;

    for _ in 0..case_count {
        if cursor >= length {
            return -1;
        }
        let n_value = *input.add(cursor);
        cursor += 1;
        if n_value < 0 || n_value > MAX_VECTORS as i64 {
            return -1;
        }
        let n = n_value as usize;
        if cursor + n > length {
            return -1;
        }
        let mut left = [0u32; MAX_VECTORS];
        let mut left_check = [0u32; MAX_BITS];
        for index in 0..n {
            let value = *input.add(cursor);
            cursor += 1;
            if value < 0 || value > MAX_VECTOR as i64
                || !insert_independent(&mut left_check, value as u32)
            {
                return -1;
            }
            left[index] = value as u32;
        }
        if cursor >= length {
            return -1;
        }
        let m_value = *input.add(cursor);
        cursor += 1;
        if m_value < 0 || m_value > MAX_VECTORS as i64 {
            return -1;
        }
        let m = m_value as usize;
        if cursor + m > length {
            return -1;
        }
        let mut right = [0u32; MAX_VECTORS];
        let mut right_check = [0u32; MAX_BITS];
        for index in 0..m {
            let value = *input.add(cursor);
            cursor += 1;
            if value < 0 || value > MAX_VECTOR as i64
                || !insert_independent(&mut right_check, value as u32)
            {
                return -1;
            }
            right[index] = value as u32;
        }
        let mut basis = [0u32; MAX_VECTORS];
        let dimension = intersection_basis(&left, n, &right, m, &mut basis);
        staged[used] = dimension as i64;
        used += 1;
        for index in 0..dimension {
            staged[used] = basis[index] as i64;
            used += 1;
        }
    }
    if cursor != length {
        return -1;
    }
    let required = 8 * used;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..used {
        store_i64_le(output, 8 * index, staged[index]);
    }
    required as i64
}
