const MAX_N: usize = 16;
const MAX_NONZER: usize = 4;
const MAX_SUPPORT: usize = 5;
const MAX_TRIPLETS: usize = 416;
const MAX_INPUT: usize = 3 + 2 * MAX_N * MAX_NONZER;
const MAX_OUTPUT: usize = 8 * (MAX_N + 3 + 2 * MAX_N * MAX_N);
const MAX_VALUE_MICRO: i64 = 1_000_000;
const MAX_SHIFT_MICRO: i64 = 10_000_000;
const SCALE: f64 = 1_000_000.0;
const RCOND: f64 = 0.1;

fn valid(values: &[i64]) -> Option<(usize, usize)> {
    if values.len() < 3 || values.len() > MAX_INPUT
        || !(2..=MAX_N as i64).contains(&values[0])
        || !(1..=MAX_NONZER as i64).contains(&values[1])
        || !(0..=MAX_SHIFT_MICRO).contains(&values[2]) {
        return None;
    }
    let n = values[0] as usize;
    let nonzer = values[1] as usize;
    if values.len() != 3 + 2 * n * nonzer { return None; }
    let mut cursor = 3;
    for _vector in 0..n {
        let mut seen = 0_u32;
        for _entry in 0..nonzer {
            let coordinate = values[cursor];
            let value = values[cursor + 1];
            cursor += 2;
            if coordinate < 0 || coordinate >= n as i64 || value == 0
                || !(-MAX_VALUE_MICRO..=MAX_VALUE_MICRO).contains(&value) {
                return None;
            }
            let bit = 1_u32 << coordinate as u32;
            if seen & bit != 0 { return None; }
            seen |= bit;
        }
    }
    Some((n, nonzer))
}

fn write_f64(output: &mut [u8], offset: &mut usize, value: f64) {
    output[*offset..*offset + 8].copy_from_slice(&value.to_bits().to_le_bytes());
    *offset += 8;
}

#[no_mangle]
pub unsafe extern "C" fn npb_cg_sparse_outer_product_assembly(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (n, nonzer) = match valid(values) { Some(parsed) => parsed, None => return -1 };

    let mut raw_rows = [0_u8; MAX_TRIPLETS];
    let mut raw_columns = [0_u8; MAX_TRIPLETS];
    let mut raw_values = [0.0_f64; MAX_TRIPLETS];
    let mut raw_count = 0;
    let mut cursor = 3;
    for vector in 0..n {
        let mut coordinates = [0_u8; MAX_SUPPORT];
        let mut vector_values = [0.0_f64; MAX_SUPPORT];
        let mut support_count = nonzer;
        let mut has_anchor = false;
        for entry in 0..nonzer {
            let coordinate = values[cursor] as usize;
            coordinates[entry] = coordinate as u8;
            vector_values[entry] = values[cursor + 1] as f64 / SCALE;
            cursor += 2;
            if coordinate == vector {
                vector_values[entry] = 0.5;
                has_anchor = true;
            }
        }
        if !has_anchor {
            coordinates[support_count] = vector as u8;
            vector_values[support_count] = 0.5;
            support_count += 1;
        }
        let weight = if vector == 0 { 1.0 }
            else if vector + 1 == n { RCOND }
            else { RCOND.powf(vector as f64 / (n - 1) as f64) };
        for column_slot in 0..support_count {
            let scaled_column = weight * vector_values[column_slot];
            for row_slot in 0..support_count {
                raw_rows[raw_count] = coordinates[row_slot];
                raw_columns[raw_count] = coordinates[column_slot];
                raw_values[raw_count] = vector_values[row_slot] * scaled_column;
                raw_count += 1;
            }
        }
    }
    let diagonal_addend = RCOND - values[2] as f64 / SCALE;
    for diagonal in 0..n {
        raw_rows[raw_count] = diagonal as u8;
        raw_columns[raw_count] = diagonal as u8;
        raw_values[raw_count] = diagonal_addend;
        raw_count += 1;
    }

    let mut column_pointers = [0_i64; MAX_N + 1];
    let mut row_indices = [0_u8; MAX_N * MAX_N];
    let mut matrix_values = [0.0_f64; MAX_N * MAX_N];
    let mut nnz = 0;
    for column in 0..n {
        column_pointers[column] = nnz as i64;
        for row in 0..n {
            let mut sum = 0.0;
            let mut touched = false;
            for triple in 0..raw_count {
                if raw_rows[triple] as usize == row && raw_columns[triple] as usize == column {
                    sum += raw_values[triple];
                    touched = true;
                }
            }
            if touched {
                row_indices[nnz] = row as u8;
                matrix_values[nnz] = sum;
                nnz += 1;
            }
        }
    }
    column_pointers[n] = nnz as i64;
    let required = 8 * (2 + (n + 1) + 2 * nnz);
    if output.is_null() || capacity < required { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, required) };
    let mut offset = 0;
    write_f64(out, &mut offset, n as f64);
    write_f64(out, &mut offset, nnz as f64);
    for pointer in &column_pointers[..=n] { write_f64(out, &mut offset, *pointer as f64); }
    for row in &row_indices[..nnz] { write_f64(out, &mut offset, *row as f64); }
    for value in &matrix_values[..nnz] { write_f64(out, &mut offset, *value); }
    required as i64
}
