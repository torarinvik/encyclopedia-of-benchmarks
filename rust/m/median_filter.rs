fn lower_bound(sorted: &[f64; 16], size: usize, value: f64) -> usize {
    let mut low = 0;
    let mut high = size;
    while low < high {
        let middle = low + (high - low) / 2;
        if sorted[middle] < value { low = middle + 1; } else { high = middle; }
    }
    low
}

#[no_mangle]
pub unsafe extern "C" fn median_filter(input: *const f64, length: usize,
                                        output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 66 { return -1; }
    let window_value = *input;
    let count_value = *input.add(1);
    if !window_value.is_finite() || window_value.fract() != 0.0 || !(1.0..=16.0).contains(&window_value) ||
        !count_value.is_finite() || count_value.fract() != 0.0 || !(0.0..=64.0).contains(&count_value) { return -1; }
    let window = window_value as usize;
    let count = count_value as usize;
    if length != 2 + count { return -1; }
    let mut samples = [0.0_f64; 64];
    for index in 0..count {
        let value = *input.add(2 + index);
        if !value.is_finite() || !(-1_000_000.0..=1_000_000.0).contains(&value) { return -1; }
        samples[index] = value;
    }
    if output.is_null() || output_capacity < count { return -2; }

    let mut arrival = [0.0_f64; 16];
    let mut sorted = [0.0_f64; 16];
    let mut result = [0.0_f64; 64];
    let (mut size, mut oldest) = (0, 0);
    for index in 0..count {
        let value = samples[index];
        if size == window {
            let position = lower_bound(&sorted, size, arrival[oldest]);
            for shift in position + 1..size { sorted[shift - 1] = sorted[shift]; }
            size -= 1;
        }
        let position = lower_bound(&sorted, size, value);
        for shift in (position..size).rev() { sorted[shift + 1] = sorted[shift]; }
        sorted[position] = value;
        arrival[oldest] = value;
        oldest = (oldest + 1) % window;
        size += 1;
        let middle = size / 2;
        result[index] = if size % 2 != 0 { sorted[middle] } else { 0.5 * (sorted[middle - 1] + sorted[middle]) };
    }
    for index in 0..count { *output.add(index) = result[index]; }
    count as i64
}
