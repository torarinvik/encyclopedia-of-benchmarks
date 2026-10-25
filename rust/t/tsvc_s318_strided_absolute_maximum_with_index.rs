const MAX_N: usize = 64;
const MAX_STRIDE: usize = 4;
const MAX_PHYSICAL_N: usize = 1 + (MAX_N - 1) * MAX_STRIDE;
const MAX_INPUT_LENGTH: usize = 2 + MAX_PHYSICAL_N;
const MAX_VALUE: i64 = 1_000_000;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s318_strided_absolute_maximum_with_index(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let stride_raw = values[1];
    if n_raw < 1 || n_raw > MAX_N as i64 || stride_raw < 1 || stride_raw > MAX_STRIDE as i64 { return -1; }
    let n = n_raw as usize;
    let stride = stride_raw as usize;
    let physical_n = 1 + (n - 1) * stride;
    if length != 2 + physical_n { return -1; }
    if values[2..].iter().any(|&value| !(-MAX_VALUE..=MAX_VALUE).contains(&value)) { return -1; }
    if output.is_null() || output_capacity < 16 { return -2; }

    let mut maximum = values[2].abs();
    let mut maximum_index = 0usize;
    for i in 1..n {
        let magnitude = values[2 + i * stride].abs();
        if magnitude > maximum {
            maximum = magnitude;
            maximum_index = i;
        }
    }
    store_i64_le(output, 0, maximum);
    store_i64_le(output, 8, maximum_index as i64);
    2
}
