const MIN_SIDE: usize = 3;
const MAX_SIDE: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MAX_OUTPUT_ELEMENTS: usize = 512;
const MAX_OUTPUT_BYTES: usize = 4096;
const KERNEL_X: [i32; 9] = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
const KERNEL_Y: [i32; 9] = [1, 2, 1, 0, 0, 0, -1, -2, -1];

fn write_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn sobel_filter(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < MIN_SIDE as i64 || values[0] > MAX_SIDE as i64 {
        return -1;
    }
    let side = values[0] as usize;
    let pixel_count = side * side;
    if input_length != pixel_count + 1 {
        return -1;
    }
    let mut image = [0_i32; MAX_SIDE * MAX_SIDE];
    for index in 0..pixel_count {
        if values[index + 1] < 0 || values[index + 1] > 255 {
            return -1;
        }
        image[index] = values[index + 1] as i32;
    }

    let mut gradient_x = [0_i32; MAX_SIDE * MAX_SIDE];
    let mut gradient_y = [0_i32; MAX_SIDE * MAX_SIDE];
    let mut max_x = 0_i32;
    let mut max_y = 0_i32;
    for y in 0..side {
        for x in 0..side {
            let mut gx = 0_i32;
            let mut gy = 0_i32;
            for ky in 0..3 {
                let sample_y = (y as isize + ky as isize - 1).clamp(0, side as isize - 1) as usize;
                for kx in 0..3 {
                    let sample_x = (x as isize + kx as isize - 1).clamp(0, side as isize - 1) as usize;
                    let pixel = image[sample_y * side + sample_x];
                    let kernel_index = ky * 3 + kx;
                    gx += pixel * KERNEL_X[kernel_index];
                    gy += pixel * KERNEL_Y[kernel_index];
                }
            }
            gx = gx.abs();
            gy = gy.abs();
            let index = y * side + x;
            gradient_x[index] = gx;
            gradient_y[index] = gy;
            max_x = max_x.max(gx);
            max_y = max_y.max(gy);
        }
    }
    if max_x == 0 || max_y == 0 {
        return -1;
    }

    let mut scaled_x = [0.0_f64; MAX_SIDE * MAX_SIDE];
    let mut scaled_y = [0.0_f64; MAX_SIDE * MAX_SIDE];
    let mut magnitude = [0.0_f64; MAX_SIDE * MAX_SIDE];
    let mut theta = [0.0_f64; MAX_SIDE * MAX_SIDE];
    let mut max_magnitude = 0.0_f64;
    for index in 0..pixel_count {
        scaled_x[index] = (f64::from(gradient_x[index]) * 255.0) / f64::from(max_x);
        scaled_y[index] = (f64::from(gradient_y[index]) * 255.0) / f64::from(max_y);
        magnitude[index] = (scaled_x[index] * scaled_x[index] + scaled_y[index] * scaled_y[index]).sqrt();
        max_magnitude = max_magnitude.max(magnitude[index]);
    }
    if max_magnitude == 0.0 {
        return -1;
    }
    for index in 0..pixel_count {
        let normalized = (magnitude[index] * 255.0) / max_magnitude;
        magnitude[index] = (normalized as u8) as f64;
        theta[index] = scaled_y[index].atan2(scaled_x[index]);
    }

    let output_elements = 2 * pixel_count;
    let output_bytes = output_elements * 8;
    if output_elements > MAX_OUTPUT_ELEMENTS || output_bytes > MAX_OUTPUT_BYTES {
        return -1;
    }
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..pixel_count {
        write_f64_le(output_slice, index * 8, magnitude[index]);
        write_f64_le(output_slice, (pixel_count + index) * 8, theta[index]);
    }
    output_elements as i64
}
