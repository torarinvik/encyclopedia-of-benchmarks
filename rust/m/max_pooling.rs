const MAX_N: usize = 16;
const MAX_INPUT_WORDS: usize = 3 + MAX_N * MAX_N;
const MAX_PARSEABLE_INPUT_WORDS: usize = MAX_INPUT_WORDS + 1;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_N * MAX_N;

#[no_mangle]
pub unsafe extern "C" fn max_pooling(input: *const i32, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_WORDS { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let n = input[0]; let size = input[1]; let stride = input[2];
    if !(1..=MAX_N as i32).contains(&n) || size < 1 || size > n || !(1..=MAX_N as i32).contains(&stride) ||
        length != 3 + n as usize * n as usize { return -1; }
    let cells = n as usize * n as usize;
    if input[3..3 + cells].iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1; }
    let out_side = ((n - size) / stride + 1) as usize;
    let output_count = out_side * out_side;
    let bytes = output_count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    let mut position = 0usize;
    for row in 0..out_side {
        for col in 0..out_side {
            let start_row = row * stride as usize;
            let start_col = col * stride as usize;
            let mut maximum = input[3 + start_row * n as usize + start_col];
            for r in 0..size as usize {
                for c in 0..size as usize {
                    maximum = maximum.max(input[3 + (start_row + r) * n as usize + start_col + c]);
                }
            }
            buffer[position..position + 8].copy_from_slice(&(maximum as f64).to_le_bytes());
            position += 8;
        }
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
