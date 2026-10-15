/// Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm.
fn is_ascii_alphanumeric(value: i64) -> bool {
    (48..=57).contains(&value) || (65..=90).contains(&value) || (97..=122).contains(&value)
}

fn transformed_equal(values: &[i64], left: usize, right: usize) -> bool {
    if (left & 1) != (right & 1) { return false; }
    (left & 1) == 0 || values[left / 2] == values[right / 2]
}

#[no_mangle]
pub extern "C" fn manacher(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length == 0 || length > 1000 || values.is_null() { return -1; }
    let input = unsafe { core::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !is_ascii_alphanumeric(value)) { return -1; }

    let mut radii = [0usize; 2001];
    let transformed_length = 2 * length + 1;
    let mut center = 0usize;
    let mut right = 0usize;
    let mut best_center = 0usize;
    let mut best_radius = 0usize;
    for index in 0..transformed_length {
        let mut radius = 0usize;
        if index < right {
            let mirror = 2 * center - index;
            radius = radii[mirror].min(right - index);
        }
        while radius < index && radius < transformed_length - 1 - index
            && transformed_equal(input, index - radius - 1, index + radius + 1)
        {
            radius += 1;
        }
        radii[index] = radius;
        if index + radius > right {
            center = index;
            right = index + radius;
        }
        if radius > best_radius {
            best_center = index;
            best_radius = radius;
        }
    }

    let best_start = (best_center - best_radius) / 2;
    if output_capacity < best_radius || output.is_null() { return -2; }
    for index in 0..best_radius {
        unsafe { *output.add(index) = input[best_start + index] as u8; }
    }
    best_radius as i64
}
