const MAX_SIDE: usize = 16;
const MAX_PIXELS: usize = MAX_SIDE * MAX_SIDE;
const NORM_SCALE: i64 = 1_048_576;
const ANGLE_SCALE: i64 = 1_000_000_000;
const TAN_22_5_Q9: i64 = 414_213_562;
const GAUSSIAN: [i64; 25] = [
    85_321, 66_110, 30_754, 8_589, 1_440,
    66_110, 51_225, 23_829, 6_655, 1_116,
    30_754, 23_829, 11_085, 3_096, 519,
    8_589, 6_655, 3_096, 865, 145,
    1_440, 1_116, 519, 145, 24,
];
const SOBEL_X: [i64; 9] = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
const SOBEL_Y: [i64; 9] = [1, 2, 1, 0, 0, 0, -1, -2, -1];

fn clamp_coordinate(coordinate: isize, side: usize) -> usize {
    if coordinate < 0 { 0 }
    else if coordinate as usize >= side { side - 1 }
    else { coordinate as usize }
}

fn integer_sqrt(value: u64) -> u64 {
    if value < 2 { return value; }
    let mut low = 1u64;
    let mut high = value.min(4_294_967_296);
    while low <= high {
        let middle = low + (high - low) / 2;
        if middle <= value / middle { low = middle + 1; }
        else { high = middle - 1; }
    }
    high
}

#[no_mangle]
pub unsafe extern "C" fn canny(values: *const i64, length: usize,
                               output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || !(2..=1 + MAX_PIXELS).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let side_value = values[0];
    if !(1..=MAX_SIDE as i64).contains(&side_value) { return -1; }
    let side = side_value as usize;
    let pixels = side * side;
    if length != pixels + 1 || values[1..].iter().any(|&value| !(0..=255).contains(&value)) {
        return -1;
    }
    if output_capacity < pixels || output.is_null() { return -2; }

    let mut blurred = [0i64; MAX_PIXELS];
    let mut gradient_x = [0i64; MAX_PIXELS];
    let mut gradient_y = [0i64; MAX_PIXELS];
    let mut normalized_x = [0i64; MAX_PIXELS];
    let mut normalized_y = [0i64; MAX_PIXELS];
    let mut magnitude = [0i64; MAX_PIXELS];
    let mut destination = [0i64; MAX_PIXELS];

    for row in 0..side {
        for column in 0..side {
            let mut total = 0i64;
            for ky in -4isize..=4 {
                let source_row = clamp_coordinate(row as isize + ky, side);
                for kx in -4isize..=4 {
                    let source_column = clamp_coordinate(column as isize + kx, side);
                    total += GAUSSIAN[ky.unsigned_abs() * 5 + kx.unsigned_abs()]
                        * values[1 + source_row * side + source_column];
                }
            }
            blurred[row * side + column] = total;
        }
    }

    let mut maximum_x = 0i64;
    let mut maximum_y = 0i64;
    for row in 0..side {
        for column in 0..side {
            let mut total_x = 0i64;
            let mut total_y = 0i64;
            for ky in -1isize..=1 {
                let source_row = clamp_coordinate(row as isize + ky, side);
                for kx in -1isize..=1 {
                    let source_column = clamp_coordinate(column as isize + kx, side);
                    let sample = blurred[source_row * side + source_column];
                    let kernel_index = ((ky + 1) * 3 + kx + 1) as usize;
                    total_x += sample * SOBEL_X[kernel_index];
                    total_y += sample * SOBEL_Y[kernel_index];
                }
            }
            let offset = row * side + column;
            gradient_x[offset] = total_x.abs();
            gradient_y[offset] = total_y.abs();
            maximum_x = maximum_x.max(gradient_x[offset]);
            maximum_y = maximum_y.max(gradient_y[offset]);
        }
    }

    let mut maximum_magnitude = 0u64;
    for index in 0..pixels {
        if maximum_x != 0 { normalized_x[index] = gradient_x[index] * 255 * NORM_SCALE / maximum_x; }
        if maximum_y != 0 { normalized_y[index] = gradient_y[index] * 255 * NORM_SCALE / maximum_y; }
        let x = normalized_x[index] as u64;
        let y = normalized_y[index] as u64;
        magnitude[index] = integer_sqrt(x * x + y * y) as i64;
        maximum_magnitude = maximum_magnitude.max(magnitude[index] as u64);
    }
    if maximum_magnitude != 0 {
        for value in &mut magnitude[..pixels] { *value = *value * 255 / maximum_magnitude as i64; }
    }

    for row in 1..side.saturating_sub(1) {
        for column in 1..side.saturating_sub(1) {
            let offset = row * side + column;
            let (before, after) = if normalized_y[offset] * ANGLE_SCALE
                < normalized_x[offset] * TAN_22_5_Q9 {
                (offset - 1, offset + 1)
            } else if normalized_x[offset] * ANGLE_SCALE
                <= normalized_y[offset] * TAN_22_5_Q9 {
                (offset - side, offset + side)
            } else {
                (offset + side - 1, offset - side + 1)
            };
            if magnitude[offset] >= magnitude[before] && magnitude[offset] >= magnitude[after] {
                destination[offset] = magnitude[offset];
            }
        }
    }
    for value in &mut destination[..pixels] {
        *value = if *value >= 30 { 255 } else if *value <= 15 { 0 } else { 128 };
    }
    for row in 1..side.saturating_sub(1) {
        for column in 1..side.saturating_sub(1) {
            let offset = row * side + column;
            if destination[offset] == 128 {
                let mut connected = false;
                for dy in -1isize..=1 {
                    for dx in -1isize..=1 {
                        if (dx != 0 || dy != 0)
                            && destination[(row as isize + dy) as usize * side
                                + (column as isize + dx) as usize] == 255 {
                            connected = true;
                        }
                    }
                }
                destination[offset] = if connected { 255 } else { 0 };
            }
        }
    }
    let result = std::slice::from_raw_parts_mut(output, pixels);
    for (target, &value) in result.iter_mut().zip(&destination[..pixels]) { *target = value as u8; }
    pixels as i64
}
