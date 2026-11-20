const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const MAX_OUTPUT_BYTES: usize = 8;

fn write_i64_le(output: &mut [u8], value: i64) {
    output[..8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn maximum_sum_contiguous_submatrix(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let rows_value = values[0];
    let columns_value = values[1];
    if !(1..=8).contains(&rows_value) || !(1..=8).contains(&columns_value) {
        return -1;
    }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    if length != 2 + cells || values[2..].iter().any(|&cell| !(-1000..=1000).contains(&cell)) {
        return -1;
    }

    let mut best = -64001_i64;
    let mut column_sums = [0_i64; 8];
    for top in 0..rows {
        column_sums.fill(0);
        for bottom in top..rows {
            let row_offset = 2 + bottom * columns;
            for column in 0..columns {
                column_sums[column] += values[row_offset + column];
            }
            let mut current = column_sums[0];
            best = best.max(current);
            for column in 1..columns {
                current = if current < 0 {
                    column_sums[column]
                } else {
                    current + column_sums[column]
                };
                best = best.max(current);
            }
        }
    }
    if output.is_null() || capacity < MAX_OUTPUT_BYTES {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, MAX_OUTPUT_BYTES);
    write_i64_le(output_slice, best);
    MAX_OUTPUT_BYTES as i64
}
