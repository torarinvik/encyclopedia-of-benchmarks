fn emit_segment(output: &mut [u8], position: &mut usize,
                x0: i64, y0: i64, x1: i64, y1: i64) {
    for value in [x0, y0, x1, y1] {
        output[*position..*position + 8].copy_from_slice(&value.to_le_bytes());
        *position += 8;
    }
}

fn draw_triangle(output: &mut [u8], position: &mut usize,
                 x1: i64, y1: i64, x2: i64, y2: i64,
                 x3: i64, y3: i64, depth: i64) {
    emit_segment(output, position, x1, y1, x2, y2);
    emit_segment(output, position, x2, y2, x3, y3);
    emit_segment(output, position, x3, y3, x1, y1);
    if depth == 0 { return; }
    let (abx, aby) = ((x1 + x2) / 2, (y1 + y2) / 2);
    let (acx, acy) = ((x1 + x3) / 2, (y1 + y3) / 2);
    let (bcx, bcy) = ((x2 + x3) / 2, (y2 + y3) / 2);
    draw_triangle(output, position, x1, y1, abx, aby, acx, acy, depth - 1);
    draw_triangle(output, position, x2, y2, abx, aby, bcx, bcy, depth - 1);
    draw_triangle(output, position, x3, y3, bcx, bcy, acx, acy, depth - 1);
}

#[no_mangle]
pub unsafe extern "C" fn sierpinski_triangle(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let depth = *input;
    if !(0..=4).contains(&depth) { return -1; }
    let mut calls = 1usize;
    for _ in 0..depth { calls = calls * 3 + 1; }
    let needed = calls * 96;
    if needed > 11616 { return -1; }
    if output.is_null() || capacity < needed { return -2; }
    let result = std::slice::from_raw_parts_mut(output, needed);
    let mut position = 0;
    draw_triangle(result, &mut position, -2800, -2000, 0, 2800, 2800, -2000, depth);
    needed as i64
}
