const MAX_SIDE: usize = 32;
const MAX_PIXELS: usize = MAX_SIDE * MAX_SIDE;

unsafe fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (byte, value_byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + byte) = *value_byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn bilateral_filter(values: *const i64, length: usize,
                                             output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 5 || length > 5 + MAX_PIXELS { return -1; }
    let height_value = *values;
    let width_value = *values.add(1);
    let kernel_value = *values.add(2);
    let spatial_q = *values.add(3);
    let intensity_q = *values.add(4);
    if !(1..=MAX_SIDE as i64).contains(&height_value) || !(1..=MAX_SIDE as i64).contains(&width_value)
        || ![1, 3, 5, 7].contains(&kernel_value) || !(1..=1_000_000).contains(&spatial_q)
        || !(1..=1_000_000).contains(&intensity_q) { return -1; }
    let height = height_value as usize;
    let width = width_value as usize;
    let pixels = height * width;
    if length != 5 + pixels { return -1; }
    for index in 0..pixels {
        let value = *values.add(5 + index);
        if !(0..=1_000_000).contains(&value) { return -1; }
    }
    let required = pixels * 8;
    if output.is_null() || output_capacity < required { return -2; }

    let radius = kernel_value as usize / 2;
    let kernel_size = kernel_value as usize;
    let row_end = if height >= kernel_size { height - radius } else { radius };
    let column_end = if width >= kernel_size { width - radius } else { radius };
    let spatial_variance = spatial_q as f64 / 1_000_000.0;
    let intensity_variance = intensity_q as f64 / 1_000_000.0;
    let mut filtered = [0i64; MAX_PIXELS];
    for row in radius..row_end {
        for column in radius..column_end {
            let center = *values.add(5 + row * width + column) as f64 / 1_000_000.0;
            let (mut weighted_sum, mut weight_sum) = (0.0, 0.0);
            for dy in -(radius as isize)..=radius as isize {
                for dx in -(radius as isize)..=radius as isize {
                    let sample_index = ((row as isize + dy) as usize) * width + (column as isize + dx) as usize;
                    let sample = *values.add(5 + sample_index) as f64 / 1_000_000.0;
                    let spatial_distance_squared = (dx * dx + dy * dy) as f64;
                    let difference = sample - center;
                    let mut weight = (-spatial_distance_squared / (2.0 * spatial_variance)).exp();
                    weight *= (-(difference * difference) / (2.0 * intensity_variance)).exp();
                    weighted_sum += sample * weight;
                    weight_sum += weight;
                }
            }
            filtered[row * width + column] = (weighted_sum / weight_sum * 1_000_000.0 + 0.5) as i64;
        }
    }
    for index in 0..pixels { write_i64_le(output, index * 8, filtered[index]); }
    required as i64
}
