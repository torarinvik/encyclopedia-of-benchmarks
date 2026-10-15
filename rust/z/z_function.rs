const MAX_LENGTH: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn z_function(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if length > MAX_LENGTH || (length > 0 && input.is_null()) {
        return -1;
    }
    let values = if length == 0 { &[][..] } else { std::slice::from_raw_parts(input, length) };
    if values.iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }
    let required = length * 8;
    if capacity < required || (required > 0 && output.is_null()) {
        return -2;
    }

    let mut z = [0_i64; MAX_LENGTH];
    let (mut left, mut right) = (0_usize, 0_usize);
    for index in 1..length {
        if index <= right {
            z[index] = ((right - index + 1).min(z[index - left] as usize)) as i64;
        }
        while index + z[index] as usize < length && values[z[index] as usize] == values[index + z[index] as usize] {
            z[index] += 1;
        }
        if index + z[index] as usize > right + 1 {
            left = index;
            right = index + z[index] as usize - 1;
        }
    }
    for index in 0..length {
        let bytes = z[index].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8);
    }
    required as i64
}
