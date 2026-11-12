const MAX_ROWS: usize = 16;
const MAX_COLUMNS: usize = 16;
const MAX_INPUT_LENGTH: usize = 260;

fn smawk(
    matrix: &[i64], column_count: usize,
    row_work: &mut [i32; 2 * MAX_ROWS], row_offset: usize, row_count: usize,
    column_work: &mut [i32; 3 * MAX_COLUMNS], input_column_offset: usize,
    input_column_count: usize, output_column_offset: usize,
    minima: &mut [i32; MAX_ROWS],
) {
    if row_count == 0 { return; }
    if row_count == 1 {
        let row = row_work[row_offset] as usize;
        let mut best = column_work[input_column_offset] as usize;
        for j in 1..input_column_count {
            let candidate = column_work[input_column_offset + j] as usize;
            if matrix[row * column_count + candidate] < matrix[row * column_count + best] { best = candidate; }
        }
        minima[row] = best as i32;
        return;
    }

    let mut reduced_count = 0;
    for j in 0..input_column_count {
        let candidate = column_work[input_column_offset + j] as usize;
        while reduced_count > 0 {
            let comparison_row = row_work[row_offset + reduced_count - 1] as usize;
            let previous = column_work[output_column_offset + reduced_count - 1] as usize;
            if matrix[comparison_row * column_count + candidate] < matrix[comparison_row * column_count + previous] {
                reduced_count -= 1;
            } else { break; }
        }
        if reduced_count < row_count {
            column_work[output_column_offset + reduced_count] = candidate as i32;
            reduced_count += 1;
        }
    }

    let odd_offset = row_offset + row_count;
    let mut odd_count = 0;
    for i in (1..row_count).step_by(2) {
        row_work[odd_offset + odd_count] = row_work[row_offset + i];
        odd_count += 1;
    }
    let child_output_offset = output_column_offset + reduced_count;
    smawk(matrix, column_count, row_work, odd_offset, odd_count,
          column_work, output_column_offset, reduced_count, child_output_offset, minima);

    let mut start_cursor = 0;
    let mut end_cursor = 0;
    for i in (0..row_count).step_by(2) {
        let start = if i == 0 {
            0
        } else {
            let target = minima[row_work[row_offset + i - 1] as usize];
            while start_cursor < reduced_count
                && column_work[output_column_offset + start_cursor] != target { start_cursor += 1; }
            start_cursor.min(reduced_count - 1)
        };
        let end = if i + 1 < row_count {
            let target = minima[row_work[row_offset + i + 1] as usize];
            if end_cursor < start { end_cursor = start; }
            while end_cursor < reduced_count
                && column_work[output_column_offset + end_cursor] != target { end_cursor += 1; }
            end_cursor.min(reduced_count - 1)
        } else { reduced_count - 1 };
        let row = row_work[row_offset + i] as usize;
        let mut best = column_work[output_column_offset + start] as usize;
        for position in start + 1..=end {
            let candidate = column_work[output_column_offset + position] as usize;
            if matrix[row * column_count + candidate] < matrix[row * column_count + best] { best = candidate; }
        }
        minima[row] = best as i32;
    }
}

#[no_mangle]
pub unsafe extern "C" fn smawk_row_minima(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_ROWS as i64).contains(&values[0])
        || !(1..=MAX_COLUMNS as i64).contains(&values[1]) { return -1; }
    let row_count = values[0] as usize;
    let column_count = values[1] as usize;
    if length != 2 + row_count * column_count { return -1; }
    let matrix = &values[2..];

    let mut row_work = [0i32; 2 * MAX_ROWS];
    let mut column_work = [0i32; 3 * MAX_COLUMNS];
    let mut minima = [0i32; MAX_ROWS];
    for i in 0..row_count { row_work[i] = i as i32; }
    for j in 0..column_count { column_work[j] = j as i32; }
    smawk(matrix, column_count, &mut row_work, 0, row_count,
          &mut column_work, 0, column_count, MAX_COLUMNS, &mut minima);

    let output_bytes = row_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..row_count {
        let bytes = (minima[i] as i64).to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(i * 8), 8);
    }
    output_bytes as i64
}
