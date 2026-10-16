const MAX_SAMPLE_COUNT: usize = 128;

fn put_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn data_normalization_standardization(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > MAX_SAMPLE_COUNT + 2 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let mode = values[0];
    let count_arg = values[1];
    if (mode != 0 && mode != 1) || !(2..=MAX_SAMPLE_COUNT as i64).contains(&count_arg)
        || length != count_arg as usize + 2 { return -1; }
    let count = count_arg as usize;
    let sample = &values[2..];
    if sample.iter().any(|&value| !(-100_000..=100_000).contains(&value)) { return -1; }
    let minimum = *sample.iter().min().unwrap();
    let maximum = *sample.iter().max().unwrap();
    if minimum == maximum { return -1; }
    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let output = std::slice::from_raw_parts_mut(output, output_bytes);

    if mode == 0 {
        let span = (maximum - minimum) as f64;
        for (index, &value) in sample.iter().enumerate() {
            let normalized = (value - minimum) as f64 / span;
            put_f64_le(output, index * 8, normalized);
        }
    } else {
        let mean = sample.iter().map(|&value| value as f64).sum::<f64>() / count as f64;
        let squared_deviations = sample.iter().map(|&value| {
            let deviation = value as f64 - mean;
            deviation * deviation
        }).sum::<f64>();
        let sample_deviation = (squared_deviations / (count - 1) as f64).sqrt();
        for (index, &value) in sample.iter().enumerate() {
            let standardized = (value as f64 - mean) / sample_deviation;
            put_f64_le(output, index * 8, standardized);
        }
    }
    output_bytes as i64
}
