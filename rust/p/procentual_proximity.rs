const MAX_ROWS: usize = 64;
const MAX_COLUMNS: usize = 8;

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for index in 0..8 { *output.add(offset + index) = bytes[index]; }
}

#[no_mangle]
pub unsafe extern "C" fn procentual_proximity(input: *const i64, length: usize,
                                                output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 2 + MAX_COLUMNS + MAX_ROWS * MAX_COLUMNS { return -1; }
    let row_value = *input;
    let column_value = *input.add(1);
    if row_value < 1 || row_value > MAX_ROWS as i64 || column_value < 1 || column_value > MAX_COLUMNS as i64 { return -1; }
    let rows = row_value as usize;
    let columns = column_value as usize;
    if length != 2 + columns + rows * columns { return -1; }
    for column in 0..columns {
        let weight = *input.add(2 + column);
        if weight != 0 && weight != 1 { return -1; }
    }
    let mut data = [[0.0_f64; MAX_COLUMNS]; MAX_ROWS];
    for row in 0..rows {
        for column in 0..columns {
            let value = *input.add(2 + columns + row * columns + column);
            if !(-10_000..=10_000).contains(&value) { return -1; }
            data[row][column] = value as f64;
        }
    }
    let output_length = rows * (columns + 1) * 8;
    if output.is_null() || output_capacity < output_length { return -2; }

    let mut scores = [0.0_f64; MAX_ROWS];
    for column in 0..columns {
        let mut minimum = data[0][column];
        let mut maximum = data[0][column];
        for row in 1..rows {
            if data[row][column] < minimum { minimum = data[row][column]; }
            if data[row][column] > maximum { maximum = data[row][column]; }
        }
        let weight = *input.add(2 + column);
        if minimum == maximum {
            if weight == 0 { for row in 0..rows { scores[row] += 1.0; } }
        } else {
            let range = maximum - minimum;
            for row in 0..rows {
                let mut item_score = (data[row][column] - minimum) / range;
                if weight == 0 { item_score = 1.0 - item_score; }
                scores[row] += item_score;
            }
        }
    }
    let mut offset = 0;
    for row in 0..rows {
        for column in 0..columns {
            write_f64_le(output, offset, data[row][column]);
            offset += 8;
        }
        write_f64_le(output, offset, scores[row]);
        offset += 8;
    }
    output_length as i64
}
