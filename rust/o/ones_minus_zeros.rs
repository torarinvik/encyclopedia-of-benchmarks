const MAX_CELLS: usize = 100_000;
const MAX_DIMENSION: i64 = 100_000;

unsafe fn read_count(output: *const u8, cell: usize) -> i64 {
    let position = 4 * cell;
    i64::from(*output.add(position)) |
        (i64::from(*output.add(position + 1)) << 8) |
        (i64::from(*output.add(position + 2)) << 16) |
        (i64::from(*output.add(position + 3)) << 24)
}

unsafe fn write_i32_le(output: *mut u8, cell: usize, value: i64) {
    let encoded = value as i32 as u32;
    let position = 4 * cell;
    *output.add(position) = encoded as u8;
    *output.add(position + 1) = (encoded >> 8) as u8;
    *output.add(position + 2) = (encoded >> 16) as u8;
    *output.add(position + 3) = (encoded >> 24) as u8;
}

/// Return the row-major matrix of ones-minus-zeros values as signed 32-bit LE values.
#[no_mangle]
pub unsafe extern "C" fn ones_minus_zeros(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let rows_arg = *values;
    let columns_arg = *values.add(1);
    if !(1..=MAX_DIMENSION).contains(&rows_arg) ||
        !(1..=MAX_DIMENSION).contains(&columns_arg) { return -1; }
    let rows = rows_arg as usize;
    let columns = columns_arg as usize;
    if rows > MAX_CELLS / columns { return -1; }
    let cells = rows * columns;
    if length != 2 + cells { return -1; }
    for cell in 0..cells {
        let value = *values.add(2 + cell);
        if value != 0 && value != 1 { return -1; }
    }
    let required = 4 * cells;
    if output.is_null() || output_capacity < required { return -2; }
    core::ptr::write_bytes(output, 0, required);

    let mut row_zero_ones = 0i64;
    let mut column_zero_ones = 0i64;
    for row in 0..rows {
        for column in 0..columns {
            if *values.add(2 + row * columns + column) == 0 { continue; }
            if row == 0 {
                row_zero_ones += 1;
            } else {
                let slot = row * columns;
                write_i32_le(output, slot, read_count(output, slot) + 1);
            }
            if column == 0 {
                column_zero_ones += 1;
            } else {
                write_i32_le(output, column, read_count(output, column) + 1);
            }
        }
    }

    for row in (1..rows).rev() {
        let row_slot = row * columns;
        let row_ones = read_count(output, row_slot);
        for column in 0..columns {
            let column_ones = if column == 0 { column_zero_ones } else { read_count(output, column) };
            let difference = 2 * row_ones + 2 * column_ones - rows as i64 - columns as i64;
            write_i32_le(output, row_slot + column, difference);
        }
    }
    for column in 0..columns {
        let column_ones = if column == 0 { column_zero_ones } else { read_count(output, column) };
        let difference = 2 * row_zero_ones + 2 * column_ones - rows as i64 - columns as i64;
        write_i32_le(output, column, difference);
    }
    cells as i64
}
