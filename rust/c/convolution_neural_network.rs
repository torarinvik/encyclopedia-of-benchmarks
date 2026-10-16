const MAX_IMAGE_SIDE: usize = 8;
const MAX_KERNEL_SIDE: usize = 4;
const MAX_FILTERS: usize = 3;
const MAX_HIDDEN: usize = 8;
const MAX_OUTPUTS: usize = 4;
const MAX_ENTRY_MICRO: i64 = 1_000_000;

fn sigmoid(value: f64) -> f64 { 1.0 / (1.0 + (-value).exp()) }

fn round_three(value: f64) -> f64 {
    let scaled = value * 1000.0;
    let lower = scaled.floor();
    let mut integer = lower as i64;
    let fraction = scaled - lower;
    if fraction > 0.5 || (fraction == 0.5 && integer % 2 != 0) { integer += 1; }
    integer as f64 / 1000.0
}

fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn convolution_neural_network(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 7 || length > 2048 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let (is_v, ks_v, stride_v, filters_v, pool_v, hidden_v, outputs_v) =
        (input[0], input[1], input[2], input[3], input[4], input[5], input[6]);
    if is_v < 2 || is_v > MAX_IMAGE_SIDE as i64 || ks_v < 1 || ks_v > MAX_KERNEL_SIDE as i64 ||
       stride_v < 1 || stride_v > 4 || filters_v < 1 || filters_v > MAX_FILTERS as i64 ||
       pool_v < 1 || pool_v > 2 || hidden_v < 1 || hidden_v > MAX_HIDDEN as i64 ||
       outputs_v < 1 || outputs_v > MAX_OUTPUTS as i64 || ks_v > is_v { return -1; }
    let (image_side, kernel_side, stride, filters, pool_side, hidden, outputs) =
        (is_v as usize, ks_v as usize, stride_v as usize, filters_v as usize,
         pool_v as usize, hidden_v as usize, outputs_v as usize);
    let conv_side = (image_side - kernel_side) / stride + 1;
    if conv_side < pool_side || conv_side % pool_side != 0 { return -1; }
    let pooled_side = conv_side / pool_side;
    let feature_count = filters * pooled_side * pooled_side;
    let image_count = image_side * image_side;
    let kernel_count = filters * kernel_side * kernel_side;
    let hidden_weight_count = hidden * feature_count;
    let output_weight_count = outputs * hidden;
    let expected_length = 7 + image_count + kernel_count + filters + hidden_weight_count + output_weight_count + hidden + outputs;
    if length != expected_length || feature_count > 192 { return -1; }

    let mut image = [0.0_f64; 64];
    let mut kernels = [0.0_f64; 48];
    let mut conv_bias = [0.0_f64; 3];
    let mut hidden_weights = [0.0_f64; 1536];
    let mut output_weights = [0.0_f64; 32];
    let mut hidden_bias = [0.0_f64; 8];
    let mut output_bias = [0.0_f64; 4];
    let mut feature_maps = [0.0_f64; 192];
    let mut flattened = [0.0_f64; 192];
    let mut hidden_output = [0.0_f64; 8];
    let mut position = 7;
    for index in 0..image_count {
        let raw = input[position]; position += 1;
        if raw < 0 || raw > MAX_ENTRY_MICRO { return -1; }
        image[index] = raw as f64 / 1_000_000.0;
    }
    for index in 0..kernel_count {
        let raw = input[position]; position += 1;
        if raw < -500_000 || raw > 500_000 { return -1; }
        kernels[index] = raw as f64 / 1_000_000.0;
    }
    for index in 0..filters {
        let raw = input[position]; position += 1;
        if raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO { return -1; }
        conv_bias[index] = raw as f64 / 1_000_000.0;
    }
    for index in 0..hidden_weight_count {
        let raw = input[position]; position += 1;
        if raw < -500_000 || raw > 500_000 { return -1; }
        hidden_weights[index] = raw as f64 / 1_000_000.0;
    }
    for index in 0..output_weight_count {
        let raw = input[position]; position += 1;
        if raw < -500_000 || raw > 500_000 { return -1; }
        output_weights[index] = raw as f64 / 1_000_000.0;
    }
    for index in 0..hidden {
        let raw = input[position]; position += 1;
        if raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO { return -1; }
        hidden_bias[index] = raw as f64 / 1_000_000.0;
    }
    for index in 0..outputs {
        let raw = input[position]; position += 1;
        if raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO { return -1; }
        output_bias[index] = raw as f64 / 1_000_000.0;
    }
    let output_bytes = outputs * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    for filter in 0..filters {
        for top in 0..conv_side {
            for left in 0..conv_side {
                let mut total = 0.0;
                for row in 0..kernel_side {
                    for column in 0..kernel_side {
                        total += image[(top * stride + row) * image_side + left * stride + column]
                            * kernels[filter * kernel_side * kernel_side + row * kernel_side + column];
                    }
                }
                feature_maps[(filter * conv_side + top) * conv_side + left] = sigmoid(total - conv_bias[filter]);
            }
        }
    }
    let mut feature_index = 0;
    let pool_area = pool_side * pool_side;
    for filter in 0..filters {
        for top in (0..conv_side).step_by(pool_side) {
            for left in (0..conv_side).step_by(pool_side) {
                let mut total = 0.0;
                for row in 0..pool_side {
                    for column in 0..pool_side {
                        total += feature_maps[(filter * conv_side + top + row) * conv_side + left + column];
                    }
                }
                flattened[feature_index] = total / pool_area as f64;
                feature_index += 1;
            }
        }
    }
    for unit in 0..hidden {
        let mut total = 0.0;
        for index in 0..feature_count { total += flattened[index] * hidden_weights[unit * feature_count + index]; }
        hidden_output[unit] = sigmoid(total - hidden_bias[unit]);
    }
    for unit in 0..outputs {
        let mut total = 0.0;
        for index in 0..hidden { total += hidden_output[index] * output_weights[unit * hidden + index]; }
        write_f64_le(output, unit * 8, round_three(sigmoid(total - output_bias[unit])));
    }
    output_bytes as i64
}
