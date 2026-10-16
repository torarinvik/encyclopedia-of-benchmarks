fn trunc_div32(value: i32) -> i32 {
    if value < 0 { -((-value) / 32) } else { value / 32 }
}

#[no_mangle]
pub unsafe extern "C" fn burkes_dithering(input: *const i64, length: usize) -> i64 {
    if length < 3 || length > 150 || input.is_null() { return -1; }
    let side_value = *input;
    let threshold_value = *input.add(1);
    if !(1..=7).contains(&side_value) || !(1..=254).contains(&threshold_value) { return -1; }
    let side = side_value as usize;
    let threshold = threshold_value as i32;
    if length != 2 + 3 * side * side { return -1; }
    for index in 2..length {
        let channel = *input.add(index);
        if !(0..=255).contains(&channel) { return -1; }
    }

    let stride = side + 4;
    let mut errors = [0_i32; 8 * 11];
    let mut white_pixels = 0_u64;
    for y in 0..side {
        for x in 0..side {
            let offset = 2 + 3 * (y * side + x);
            let blue = *input.add(offset) as i32;
            let green = *input.add(offset + 1) as i32;
            let red = *input.add(offset + 2) as i32;
            let gray = (114 * blue + 587 * green + 299 * red) / 1000;
            let adjusted = gray + errors[y * stride + x];
            let white = adjusted >= threshold;
            let current_error = adjusted - if white { 255 } else { 0 };
            if white { white_pixels |= 1_u64 << (y * side + x); }
            errors[y * stride + x + 1] += trunc_div32(8 * current_error);
            errors[y * stride + x + 2] += trunc_div32(4 * current_error);
            errors[(y + 1) * stride + x] += trunc_div32(8 * current_error);
            errors[(y + 1) * stride + x + 1] += trunc_div32(4 * current_error);
            errors[(y + 1) * stride + x + 2] += trunc_div32(2 * current_error);
            if x >= 1 { errors[(y + 1) * stride + x - 1] += trunc_div32(4 * current_error); }
            if x >= 2 { errors[(y + 1) * stride + x - 2] += trunc_div32(2 * current_error); }
        }
    }
    white_pixels as i64
}
