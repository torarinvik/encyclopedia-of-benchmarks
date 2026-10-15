fn store_i64_le(value: i64, output: &mut [u8], offset: usize) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

/// Multiply two bounded square integer matrices and emit row-major i64 cells.
#[no_mangle]
pub unsafe extern "C" fn matrix_multiplication(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 {
        return -2;
    }
    let input = std::slice::from_raw_parts(input, length);
    let dimension = input[0];
    if !(2..=8).contains(&dimension) {
        return -2;
    }
    let n = dimension as usize;
    let cells = n * n;
    if length != 1 + 2 * cells || input[1..].iter().any(|&value| !(-1000..=1000).contains(&value)) {
        return -2;
    }
    if output.is_null() || output_capacity < cells * 8 {
        return -3;
    }
    let output = std::slice::from_raw_parts_mut(output, cells * 8);
    for row in 0..n {
        for column in 0..n {
            let mut sum = 0_i64;
            for index in 0..n {
                sum += input[1 + row * n + index] * input[1 + cells + index * n + column];
            }
            store_i64_le(sum, output, (row * n + column) * 8);
        }
    }
    cells as i64
}
