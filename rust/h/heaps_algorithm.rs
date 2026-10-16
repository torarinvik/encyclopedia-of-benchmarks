const MAX_VALUES: usize = 6;
const BYTES_PER_VALUE: usize = 8;

fn emit_row(values: &[i64; MAX_VALUES], n: usize, output: &mut [u8], rows: &mut usize) {
    let row_offset = *rows * n * BYTES_PER_VALUE;
    for index in 0..n {
        output[row_offset + index * BYTES_PER_VALUE..row_offset + (index + 1) * BYTES_PER_VALUE]
            .copy_from_slice(&values[index].to_le_bytes());
    }
    *rows += 1;
}

fn generate(values: &mut [i64; MAX_VALUES], n: usize, k: usize,
            output: &mut [u8], rows: &mut usize) {
    if k == 1 {
        emit_row(values, n, output, rows);
        return;
    }
    generate(values, n, k - 1, output, rows);
    for index in 0..k - 1 {
        let swap_index = if k % 2 == 0 { index } else { 0 };
        values.swap(swap_index, k - 1);
        generate(values, n, k - 1, output, rows);
    }
}

#[no_mangle]
pub unsafe extern "C" fn heaps_algorithm(values: *const i64, length: usize,
                                           output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || !(1..=MAX_VALUES).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let mut row_count = 1usize;
    for factor in 2..=length { row_count *= factor; }
    let required = row_count * length * BYTES_PER_VALUE;
    if output.is_null() || capacity < required { return -2; }
    let mut items = [0i64; MAX_VALUES];
    items[..length].copy_from_slice(input);
    let buffer = std::slice::from_raw_parts_mut(output, required);
    let mut rows = 0usize;
    generate(&mut items, length, length, buffer, &mut rows);
    rows as i64
}
