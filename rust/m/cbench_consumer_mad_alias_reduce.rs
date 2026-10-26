const MAX_INPUT_LENGTH: usize = 65;
const CS: [i64; 8] = [0x0db84a81, 0x0e1b9d7f, 0x0f31adcf, 0x0fbba815,
    0x0feda417, 0x0ffc8fc8, 0x0fff964c, 0x0ffff8d3];
const CA: [i64; 8] = [-0x083b5fe7, -0x078c36d2, -0x05039814, -0x02e91dd1,
    -0x0183603a, -0x00a7cb87, -0x003a2847, -0x000f27b4];

fn floor_div(value: i64, divisor: i64) -> i64 {
    let quotient = value / divisor;
    if value % divisor < 0 { quotient - 1 } else { quotient }
}
fn mad_mul(left: i64, right: i64) -> i64 {
    floor_div(left + 2048, 4096) * floor_div(right + 32768, 65536)
}

#[no_mangle]
pub unsafe extern "C" fn cbench_consumer_mad_alias_reduce(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=4).contains(&values[0]) { return -1; }
    let boundaries = values[0] as usize;
    if length != 1 + 16 * boundaries || values[1..].iter().any(|&v| !(-100_000_000..=100_000_000).contains(&v)) { return -1; }
    let output_size = 64 * boundaries;
    let mut staged = [0u8; 256];
    for boundary in 0..boundaries {
        let base = 1 + 16 * boundary;
        for i in 0..8 {
            let a = values[base + 2 * i];
            let b = values[base + 2 * i + 1];
            let left = (mad_mul(a, CS[i]) + mad_mul(-b, CA[i])) as i32;
            let right = (mad_mul(b, CS[i]) + mad_mul(a, CA[i])) as i32;
            let at = 64 * boundary + 8 * i;
            staged[at..at + 4].copy_from_slice(&left.to_le_bytes());
            staged[at + 4..at + 8].copy_from_slice(&right.to_le_bytes());
        }
    }
    if output.is_null() || capacity < output_size { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_size); }
    output_size as i64
}
