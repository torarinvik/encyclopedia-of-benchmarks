const MAX_SIDE: usize = 12;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;
const MAX_SAMPLES: usize = MAX_CELLS;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_CELLS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 1;

unsafe fn sample_code(input: *const i64, base: usize, side: usize,
                      row: usize, column: usize, count: usize,
                      stride: usize) -> u16 {
    let mut code = 0u16;
    for offset in 0..count {
        let at = base + row * side + column + offset * stride;
        code = 4 * code + *input.add(at) as u16;
    }
    code
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn two_dimensional_optimal_expected_matching(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }

    let n_value = *input;
    let m_value = *input.add(1);
    if n_value < 1 || n_value > MAX_SIDE as i64 || m_value < 1 || m_value > n_value {
        return -1;
    }

    let n = n_value as usize;
    let m = m_value as usize;
    let text_size = n * n;
    let pattern_size = m * m;
    if length != 2 + text_size + pattern_size {
        return -1;
    }

    let pattern_base = 2 + text_size;
    for index in 0..text_size + pattern_size {
        let value = *input.add(2 + index);
        if !(0..=3).contains(&value) {
            return -1;
        }
    }

    let mut q = 1usize;
    let mut code_capacity = 4usize;
    while code_capacity < pattern_size {
        q += 1;
        code_capacity *= 4;
    }
    let stride = m / q;
    let final_offset = (q - 1) * stride;

    let mut heads = [-1i16; 256];
    let mut next = [0i16; MAX_SAMPLES];
    let mut address_row = [0u8; MAX_SAMPLES];
    let mut address_column = [0u8; MAX_SAMPLES];
    let mut address_count = 0usize;
    for row in 0..m {
        for residue in 0..stride {
            let code = sample_code(input, pattern_base, m, row, residue, q, stride) as usize;
            address_row[address_count] = row as u8;
            address_column[address_count] = residue as u8;
            next[address_count] = heads[code];
            heads[code] = address_count as i16;
            address_count += 1;
        }
    }

    let mut tested = [false; MAX_CELLS];
    let mut matched = [false; MAX_CELLS];
    let row_starts = n - m + 1;
    let column_starts = n - m + 1;
    let mut text_row = 0usize;
    while text_row < n {
        let mut text_column = 0usize;
        while text_column + final_offset < n {
            let code = sample_code(input, 2, n, text_row, text_column, q, stride) as usize;
            let mut address = heads[code];
            while address >= 0 {
                let slot = address as usize;
                let candidate_row = text_row as isize - address_row[slot] as isize;
                let candidate_column = text_column as isize - address_column[slot] as isize;
                if candidate_row >= 0 && candidate_column >= 0
                    && (candidate_row as usize) < row_starts
                    && (candidate_column as usize) < column_starts
                {
                    let row = candidate_row as usize;
                    let column = candidate_column as usize;
                    let candidate = row * n + column;
                    if !tested[candidate] {
                        tested[candidate] = true;
                        let mut equal = true;
                        for pattern_row in 0..m {
                            for pattern_column in 0..m {
                                let text_at = 2 + (row + pattern_row) * n + column + pattern_column;
                                let pattern_at = pattern_base + pattern_row * m + pattern_column;
                                if *input.add(text_at) != *input.add(pattern_at) {
                                    equal = false;
                                    break;
                                }
                            }
                            if !equal {
                                break;
                            }
                        }
                        matched[candidate] = equal;
                    }
                }
                address = next[slot];
            }
            text_column += stride;
        }
        text_row += m;
    }

    let mut match_count = 0usize;
    for row in 0..row_starts {
        for column in 0..column_starts {
            if matched[row * n + column] {
                match_count += 1;
            }
        }
    }

    let output_bytes = 8 * (1 + 2 * match_count);
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    put_i64_le(output, 0, match_count as i64);
    let mut output_word = 1usize;
    for row in 0..row_starts {
        for column in 0..column_starts {
            if !matched[row * n + column] {
                continue;
            }
            put_i64_le(output, 8 * output_word, row as i64);
            output_word += 1;
            put_i64_le(output, 8 * output_word, column as i64);
            output_word += 1;
        }
    }
    output_bytes as i64
}
