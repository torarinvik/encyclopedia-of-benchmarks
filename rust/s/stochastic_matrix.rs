const MAX_DIMENSION: usize = 63;
const MAX_INPUT_VALUES: usize = 3 + MAX_DIMENSION * MAX_DIMENSION;
const MAX_ABS_CELL: i64 = 1_000_000_000_000;
const CELL_SCALE: f64 = 1.0e12;
const TOLERANCE: f64 = 1.0e-9;

#[no_mangle]
pub unsafe extern "C" fn stochastic_matrix(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mode = values[0];
    let rows_value = values[1];
    let columns_value = values[2];
    if (mode != 0 && mode != 1) || !(1..=MAX_DIMENSION as i64).contains(&rows_value) ||
        !(1..=MAX_DIMENSION as i64).contains(&columns_value) { return -1; }

    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let total = rows * columns;
    if length != 3 + total { return -1; }

    for &units in &values[3..] {
        if !(-MAX_ABS_CELL..=MAX_ABS_CELL).contains(&units) { return -1; }
    }

    if mode == 0 {
        for row in 0..rows {
            let mut sum = 0.0f64;
            for column in 0..columns {
                let value = values[3 + row * columns + column] as f64 / CELL_SCALE;
                if value < 0.0 { return 0; }
                sum += value;
            }
            let difference = sum - 1.0;
            if difference > TOLERANCE || difference < -TOLERANCE { return 0; }
        }
    } else {
        for column in 0..columns {
            let mut sum = 0.0f64;
            for row in 0..rows {
                let value = values[3 + row * columns + column] as f64 / CELL_SCALE;
                if value < 0.0 { return 0; }
                sum += value;
            }
            let difference = sum - 1.0;
            if difference > TOLERANCE || difference < -TOLERANCE { return 0; }
        }
    }
    1
}
