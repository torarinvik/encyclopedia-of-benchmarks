#[no_mangle]
pub extern "C" fn number_of_ways_of_cutting_a_pizza(input: *const i64, length: usize) -> i64 {
    const MAX_INPUT: usize = 39;
    const MODULUS: i64 = 1_000_000_007;
    if input.is_null() || length < 3 || length > MAX_INPUT {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let rows_value = packed[0];
    let columns_value = packed[1];
    let cuts_value = packed[2];
    if !(1..=6).contains(&rows_value) || !(1..=6).contains(&columns_value)
        || !(0..=5).contains(&cuts_value)
    {
        return -1;
    }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cuts = cuts_value as usize;
    if length != 3 + rows * columns {
        return -1;
    }
    let mut cells = [0i64; 36];
    for index in 0..rows * columns {
        let cell = packed[3 + index];
        if cell != 0 && cell != 1 {
            return -1;
        }
        cells[index] = cell;
    }

    let mut suffix = [0i64; 49];
    for row_offset in 0..rows {
        let row = rows - 1 - row_offset;
        for column_offset in 0..columns {
            let column = columns - 1 - column_offset;
            let at = row * 7 + column;
            suffix[at] = cells[row * columns + column]
                + suffix[(row + 1) * 7 + column]
                + suffix[row * 7 + column + 1]
                - suffix[(row + 1) * 7 + column + 1];
        }
    }

    let mut previous = [0i64; 49];
    let mut current = [0i64; 49];
    for row in 0..rows {
        for column in 0..columns {
            if suffix[row * 7 + column] > 0 {
                previous[row * 7 + column] = 1;
            }
        }
    }
    for _remaining in 0..cuts {
        current.fill(0);
        for row_offset in 0..rows {
            let row = rows - 1 - row_offset;
            for column_offset in 0..columns {
                let column = columns - 1 - column_offset;
                let origin = row * 7 + column;
                let mut ways = 0i64;
                for cut_row in row + 1..rows {
                    if suffix[origin] - suffix[cut_row * 7 + column] > 0 {
                        ways += previous[cut_row * 7 + column];
                    }
                }
                for cut_column in column + 1..columns {
                    if suffix[origin] - suffix[row * 7 + cut_column] > 0 {
                        ways += previous[row * 7 + cut_column];
                    }
                }
                current[origin] = ways % MODULUS;
            }
        }
        previous = current;
    }
    previous[0]
}
