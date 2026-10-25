const INPUT_COUNT: usize = 40;
const MAX_INPUT_LENGTH: usize = 41;
const OUTPUT_BYTES: usize = 112;

fn asr2(value: i64) -> i64 {
    if value >= 0 { value / 4 } else { -(((-value) + 3) / 4) }
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn mediabench_gsm_rpe_grid_selection(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|&x| !(-32768..=32767).contains(&x)) { return -1; }
    if input_length != INPUT_COUNT { return -1; }
    let mut best_score = -1_i64;
    let mut best_grid = 0_i64;
    for grid in 0_i64..4 {
        let mut sum = 0_i64;
        for i in 0_i64..13 {
            let scaled = asr2(values[(grid + 3 * i) as usize]);
            sum += scaled * scaled;
        }
        let score = 2 * sum;
        if score > best_score { best_score = score; best_grid = grid; }
    }
    let mut staged = [0_i64; 14];
    staged[0] = best_grid;
    for i in 0_i64..13 { staged[(1 + i) as usize] = values[(best_grid + 3 * i) as usize]; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, OUTPUT_BYTES) };
    for i in 0..14 { store_i64_le(out, 8 * i, staged[i]); }
    OUTPUT_BYTES as i64
}
