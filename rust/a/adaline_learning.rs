const MAX_SAMPLES: usize = 32;
const MAX_FEATURES: usize = 8;

unsafe fn store_i32_le(value: i64, output: *mut u8, offset: usize) {
    let bits = value as i32 as u32;
    for byte in 0..4 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub extern "C" fn adaline_learning(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=MAX_SAMPLES as i64).contains(&values[0])
        || !(1..=MAX_FEATURES as i64).contains(&values[1])
        || values[2] < 1
        || !(1..=12).contains(&values[3])
        || !(1..=500).contains(&values[4])
    {
        return -1;
    }

    let sample_count = values[0] as usize;
    let feature_count = values[1] as usize;
    let eta_numerator = values[2];
    let eta_shift = values[3] as u32;
    let max_iterations = values[4] as usize;
    let scale = 1_i64 << eta_shift;
    if eta_numerator >= scale || length != 5 + sample_count * (feature_count + 1) {
        return -1;
    }

    for sample in 0..sample_count {
        let row = 5 + sample * (feature_count + 1);
        if values[row..row + feature_count]
            .iter()
            .any(|&feature| !(-16..=16).contains(&feature))
        {
            return -1;
        }
        let label = values[row + feature_count];
        if label != -1 && label != 1 {
            return -1;
        }
    }

    let bytes = 4 * (1 + feature_count + 1 + sample_count);
    if output_capacity < bytes || output.is_null() {
        return -2;
    }

    let mut weights = [0_i64; MAX_FEATURES];
    weights[..feature_count].fill(scale);
    let mut bias = scale;
    let mut iterations = 0;
    for _ in 0..max_iterations {
        let mut mistakes = 0;
        for sample in 0..sample_count {
            let row = 5 + sample * (feature_count + 1);
            let mut score = bias;
            for feature in 0..feature_count {
                score += values[row + feature] * weights[feature];
            }
            let prediction = if score > 0 { 1 } else { -1 };
            let error = values[row + feature_count] - prediction;
            if error != 0 {
                mistakes += 1;
                let correction = eta_numerator * error;
                for feature in 0..feature_count {
                    weights[feature] += correction * values[row + feature];
                }
                bias += correction;
            }
        }
        iterations += 1;
        if mistakes == 0 {
            break;
        }
    }

    let mut position = 0;
    unsafe {
        store_i32_le(iterations, output, position);
        position += 4;
        for &weight in &weights[..feature_count] {
            store_i32_le(weight, output, position);
            position += 4;
        }
        store_i32_le(bias, output, position);
        position += 4;
        for sample in 0..sample_count {
            let row = 5 + sample * (feature_count + 1);
            let mut score = bias;
            for feature in 0..feature_count {
                score += values[row + feature] * weights[feature];
            }
            store_i32_le(if score > 0 { 1 } else { -1 }, output, position);
            position += 4;
        }
    }
    bytes as i64
}
