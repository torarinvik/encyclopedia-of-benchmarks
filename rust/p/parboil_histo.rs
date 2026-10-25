const MAX_BINS: usize = 256;
const MAX_SAMPLES: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn parboil_histo(input: *const i64, length: usize,
                                        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 3 + MAX_SAMPLES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let iterations = values[0];
    let bins = values[1];
    let samples = values[2];
    if iterations < 0 || iterations > 8 || bins < 1 || bins > MAX_BINS as i64 ||
       samples < 0 || samples > MAX_SAMPLES as i64 || length != 3 + samples as usize { return -1; }
    for &value in &values[3..] { if value < 0 || value >= bins { return -1; } }
    if output.is_null() || capacity < bins as usize { return -2; }
    let mut histogram = [0u8; MAX_BINS];
    for _ in 0..iterations {
        histogram[..bins as usize].fill(0);
        for &value in &values[3..] {
            let count = &mut histogram[value as usize];
            if *count < u8::MAX { *count += 1; }
        }
    }
    std::ptr::copy_nonoverlapping(histogram.as_ptr(), output, bins as usize);
    bins
}
