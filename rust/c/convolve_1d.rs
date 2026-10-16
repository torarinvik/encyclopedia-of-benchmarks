const MAX_SIGNAL_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_SIGNAL_LENGTH;
const MAX_FIXED_SAMPLE: i64 = 128;
const SAMPLE_SCALE: f64 = 16.0;

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 {
        *output.add(offset + byte) = bytes[byte];
    }
}

#[no_mangle]
pub unsafe extern "C" fn convolve_1d(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let raw_signal_count = *input;
    let raw_kernel_count = *input.add(1);
    if raw_signal_count < 0 || raw_signal_count > MAX_SIGNAL_LENGTH as i64
        || raw_kernel_count < 0 || raw_kernel_count > MAX_SIGNAL_LENGTH as i64 {
        return -1;
    }
    let signal_count = raw_signal_count as usize;
    let kernel_count = raw_kernel_count as usize;
    if length != 2 + signal_count + kernel_count {
        return -1;
    }
    for index in 0..signal_count + kernel_count {
        let value = *input.add(index + 2);
        if value < -MAX_FIXED_SAMPLE || value > MAX_FIXED_SAMPLE {
            return -1;
        }
    }

    let output_bytes = signal_count * 8;
    if output_capacity < output_bytes || (output_bytes > 0 && output.is_null()) {
        return -2;
    }
    let center = kernel_count / 2;
    for i in 0..signal_count {
        let mut accumulated = 0.0;
        for j in 0..kernel_count {
            let signal_index = i as isize + j as isize - center as isize;
            if signal_index >= 0 && signal_index < signal_count as isize {
                let kernel_value = (*input.add(2 + signal_count + j) as f64) / SAMPLE_SCALE;
                let signal_value = (*input.add(2 + signal_index as usize) as f64) / SAMPLE_SCALE;
                accumulated += kernel_value * signal_value;
            }
        }
        write_f64_le(output, i * 8, accumulated);
    }
    output_bytes as i64
}
