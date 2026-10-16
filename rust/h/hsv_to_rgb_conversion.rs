fn section_remainder_two(section: f64) -> f64 {
    if section < 2.0 { section }
    else if section < 4.0 { section - 2.0 }
    else if section < 6.0 { section - 4.0 }
    else { section - 6.0 }
}

fn round_channel(channel: f64) -> u8 {
    (255.0 * channel + 0.5) as u8
}

#[no_mangle]
pub unsafe extern "C" fn hsv_to_rgb_conversion(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, 3);
    if values[0] < 0 || values[0] > 360_000 ||
        values[1] < 0 || values[1] > 255_000_000 ||
        values[2] < 0 || values[2] > 255_000_000 { return -1; }
    if output.is_null() || capacity < 3 { return -2; }

    let hue = values[0] as f64 / 1000.0;
    let saturation = values[1] as f64 / 255_000_000.0;
    let value = values[2] as f64 / 255_000_000.0;
    let chroma = value * saturation;
    let hue_section = hue / 60.0;
    let remainder = section_remainder_two(hue_section);
    let second = chroma * (1.0 - (remainder - 1.0).abs());
    let matched = value - chroma;
    let (red, green, blue) = if hue_section >= 0.0 && hue_section <= 1.0 {
        (chroma + matched, second + matched, matched)
    } else if hue_section > 1.0 && hue_section <= 2.0 {
        (second + matched, chroma + matched, matched)
    } else if hue_section > 2.0 && hue_section <= 3.0 {
        (matched, chroma + matched, second + matched)
    } else if hue_section > 3.0 && hue_section <= 4.0 {
        (matched, second + matched, chroma + matched)
    } else if hue_section > 4.0 && hue_section <= 5.0 {
        (second + matched, matched, chroma + matched)
    } else {
        (chroma + matched, matched, second + matched)
    };
    let result = std::slice::from_raw_parts_mut(output, 3);
    result[0] = round_channel(red);
    result[1] = round_channel(green);
    result[2] = round_channel(blue);
    3
}
