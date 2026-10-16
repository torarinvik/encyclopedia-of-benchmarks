fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn is_filled(mut row: usize, mut col: usize) -> bool {
    while row != 0 || col != 0 {
        if row % 3 == 1 && col % 3 == 1 {
            return false;
        }
        row /= 3;
        col /= 3;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn sierpinski_carpet(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (depth, filled, hole) = (values[0], values[1], values[2]);
    if !(0..=4).contains(&depth)
        || !(32..=126).contains(&filled)
        || !(32..=126).contains(&hole)
        || filled == hole
    {
        return -1;
    }
    let side = 3usize.pow(depth as u32);
    let needed = 8 + side * side + side - 1;
    if output.is_null() || capacity < needed {
        return -2;
    }
    let result = std::slice::from_raw_parts_mut(output, needed);
    write_i64_le(result, 0, side as i64);
    let mut out = 8;
    for row in 0..side {
        for col in 0..side {
            result[out] = if is_filled(row, col) { filled as u8 } else { hole as u8 };
            out += 1;
        }
        if row + 1 < side {
            result[out] = b'\n';
            out += 1;
        }
    }
    needed as i64
}
