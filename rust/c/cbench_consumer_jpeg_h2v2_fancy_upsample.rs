// Independently written bounded IJG h2v2 adaptation; see package README/LICENSE.
#[no_mangle]
pub unsafe extern "C" fn cbench_consumer_jpeg_h2v2_fancy_upsample(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(5..=131).contains(&length) { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if !(3..=16).contains(&values[0]) || !(1..=8).contains(&values[1]) { return -1; }
    let width = values[0] as usize;
    let height = values[1] as usize;
    let pixels = width * height;
    if length != 2 + pixels || values[2..].iter().any(|&v| !(0..=255).contains(&v)) { return -1; }
    let output_size = 4 * pixels;
    if output.is_null() || capacity < output_size { return -2; }
    let mut staged = [0u8; 512];
    let mut p = 0;
    for y in 0..height {
        for v in 0..2 {
            let far_y = if v == 0 { y.saturating_sub(1) } else { (y + 1).min(height - 1) };
            let mut sums = [0i32; 16];
            for x in 0..width {
                sums[x] = 3 * values[2 + y * width + x] as i32 + values[2 + far_y * width + x] as i32;
            }
            staged[p] = ((sums[0] * 4 + 8) >> 4) as u8; p += 1;
            staged[p] = ((sums[0] * 3 + sums[1] + 7) >> 4) as u8; p += 1;
            for x in 1..width - 1 {
                staged[p] = ((sums[x] * 3 + sums[x - 1] + 8) >> 4) as u8; p += 1;
                staged[p] = ((sums[x] * 3 + sums[x + 1] + 7) >> 4) as u8; p += 1;
            }
            staged[p] = ((sums[width - 1] * 3 + sums[width - 2] + 8) >> 4) as u8; p += 1;
            staged[p] = ((sums[width - 1] * 4 + 7) >> 4) as u8; p += 1;
        }
    }
    for i in 0..output_size { unsafe { output.add(i).write(staged[i]); } }
    output_size as i64
}
