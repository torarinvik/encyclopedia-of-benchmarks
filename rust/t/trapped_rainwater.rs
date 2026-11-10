fn trapped_water_with_suffix(heights: &[i64], suffix: &mut [u32]) -> i64 {
    let suffix = &mut suffix[..heights.len()];
    let mut boundary = 0;
    for (&height, maximum) in heights.iter().zip(suffix.iter_mut()).rev() {
        let raw = height as u64;
        if raw > 1_000_000 { return -1; }
        boundary = boundary.max(raw as u32);
        *maximum = boundary;
    }

    let mut water = 0;
    boundary = 0;
    for (&height, &right_max) in heights.iter().zip(suffix.iter()) {
        let height = height as u32;
        boundary = boundary.max(height);
        water += boundary.min(right_max) - height;
    }
    i64::from(water)
}

/// Sum trapped water using stored suffix maxima and a running prefix maximum.
#[no_mangle]
pub extern "C" fn trapped_rainwater(heights: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && heights.is_null()) { return -1; }
    if length == 0 { return 0; }
    let heights = unsafe { std::slice::from_raw_parts(heights, length) };
    if length <= 16 {
        return trapped_water_with_suffix(heights, &mut [0; 16]);
    }
    trapped_water_with_suffix(heights, &mut [0; 4096])
}
