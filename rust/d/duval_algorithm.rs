/// Lyndon factorization using Duval's linear-time algorithm.
const MAX_LENGTH: usize = 4096;

fn valid_input(values: &[i64]) -> bool {
    values.len() <= MAX_LENGTH && values.iter().all(|&value| (0..=127).contains(&value))
}

fn factor_count(values: &[i64]) -> usize {
    let mut start = 0;
    let mut count = 0;
    while start < values.len() {
        let mut end = start + 1;
        let mut repeat = start;
        while end < values.len() && values[repeat] <= values[end] {
            if values[repeat] < values[end] { repeat = start; }
            else { repeat += 1; }
            end += 1;
        }
        let factor_length = end - repeat;
        while start <= repeat {
            count += 1;
            start += factor_length;
        }
    }
    count
}

fn store_u32_le(output: &mut [u8], offset: usize, value: usize) {
    let packed = value as u32;
    output[offset..offset + 4].copy_from_slice(&packed.to_le_bytes());
}

fn write_factors(values: &[i64], output: &mut [u8]) {
    let mut start = 0;
    let mut factor_index = 0;
    while start < values.len() {
        let mut end = start + 1;
        let mut repeat = start;
        while end < values.len() && values[repeat] <= values[end] {
            if values[repeat] < values[end] { repeat = start; }
            else { repeat += 1; }
            end += 1;
        }
        let factor_length = end - repeat;
        while start <= repeat {
            store_u32_le(output, 4 * factor_index, factor_length);
            factor_index += 1;
            start += factor_length;
        }
    }
}

#[no_mangle]
pub extern "C" fn duval_algorithm(values: *const i64, length: usize,
                                   output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    let values = if length == 0 { &[] } else {
        unsafe { std::slice::from_raw_parts(values, length) }
    };
    if !valid_input(values) { return -1; }
    let count = factor_count(values);
    let required = 4 * count;
    if required == 0 { return 0; }
    if output.is_null() || output_capacity < required { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, required) };
    write_factors(values, output);
    count as i64
}
