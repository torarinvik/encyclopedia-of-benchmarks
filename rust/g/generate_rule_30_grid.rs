const MAX_WIDTH: i64 = 64;
const MAX_GENERATIONS: i64 = 64;

#[no_mangle]
pub unsafe extern "C" fn generate_rule_30_grid(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let width_value = values[0];
    let generations_value = values[1];
    if !(1..=MAX_WIDTH).contains(&width_value) || !(1..=MAX_GENERATIONS).contains(&generations_value) {
        return -1;
    }
    let width = width_value as usize;
    let generations = generations_value as usize;
    let output_count = width * generations;
    if output_capacity < output_count || output.is_null() { return -2; }

    let mut current = [0i64; 64];
    let mut next = [0i64; 64];
    current[width / 2] = 1;
    for column in 0..width { *output.add(column) = current[column] as u8; }
    for generation in 1..generations {
        for column in 0..width {
            let left = if column > 0 { current[column - 1] } else { 0 };
            let right = if column + 1 < width { current[column + 1] } else { 0 };
            let pattern = (left * 4 + current[column] * 2 + right) as u32;
            next[column] = ((30u32 >> pattern) & 1) as i64;
        }
        for column in 0..width {
            current[column] = next[column];
            *output.add(generation * width + column) = next[column] as u8;
        }
    }
    output_count as i64
}
