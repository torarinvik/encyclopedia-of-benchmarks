const MAX_N: usize = 7;

fn emit_row(items: &[u8; MAX_N], n: usize, output: &mut [u8], rows: &mut usize) {
    let offset = *rows * n;
    output[offset..offset + n].copy_from_slice(&items[..n]);
    *rows += 1;
}

fn generate(items: &mut [u8; MAX_N], n: usize, size: usize,
            output: &mut [u8], rows: &mut usize) {
    if size == 1 {
        emit_row(items, n, output, rows);
        return;
    }
    for index in 0..size {
        generate(items, n, size - 1, output, rows);
        let swap_index = if size % 2 == 1 { index } else { 0 };
        items.swap(swap_index, size - 1);
    }
}

#[no_mangle]
pub unsafe extern "C" fn heaps(values: *const i64, length: usize,
                                output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let n64 = *values;
    if !(0..=MAX_N as i64).contains(&n64) { return -1; }
    let n = n64 as usize;
    if n == 0 { return 0; }
    let mut row_count = 1usize;
    for factor in 2..=n { row_count *= factor; }
    let required = row_count * n;
    if output.is_null() || capacity < required { return -2; }
    let mut items = [0u8; MAX_N];
    for index in 0..n { items[index] = b'1' + index as u8; }
    let buffer = std::slice::from_raw_parts_mut(output, required);
    let mut rows = 0usize;
    generate(&mut items, n, n, buffer, &mut rows);
    rows as i64
}
