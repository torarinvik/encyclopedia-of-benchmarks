const MAX_POINTS: usize = 29;
#[derive(Clone, Copy, Default)]
struct Point { x: f32, y: f32 }

#[no_mangle]
pub unsafe extern "C" fn koch_snowflake(input: *const f64, length: usize,
    output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 20 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !values[0].is_finite() || values[0].fract() != 0.0 || !(0.0..=1.0).contains(&values[0]) ||
       !values[1].is_finite() || values[1].fract() != 0.0 || !(2.0..=8.0).contains(&values[1]) { return -1; }
    let steps = values[0] as usize;
    let point_count = values[1] as usize;
    if length != 2 + 2 * point_count { return -1; }
    if values[2..].iter().any(|v| !v.is_finite() || v.abs() > 1000.0) { return -1; }
    let result_points = if steps == 0 { point_count } else { 4 * (point_count - 1) + 1 };
    let result_count = 2 * result_points;
    if output.is_null() || output_capacity < result_count { return -2; }

    let mut first = [Point::default(); MAX_POINTS];
    let mut second = [Point::default(); MAX_POINTS];
    for i in 0..point_count { first[i] = Point { x: values[2 + 2*i] as f32, y: values[3 + 2*i] as f32 }; }
    let mut source = &mut first;
    let mut destination = &mut second;
    let mut source_count = point_count;
    for _ in 0..steps {
        let mut cursor = 0;
        for i in 0..source_count - 1 {
            let start = source[i]; let end = source[i+1];
            let dx = end.x - start.x; let dy = end.y - start.y;
            let tx = dx / 3.0f32; let ty = dy / 3.0f32;
            let first_x = start.x + tx; let first_y = start.y + ty;
            let rx = 0.49999997f32 * tx - 0.86602545f32 * ty;
            let ry = 0.86602545f32 * tx + 0.49999997f32 * ty;
            let peak_x = first_x + rx; let peak_y = first_y + ry;
            let tx2 = dx * 2.0f32 / 3.0f32; let ty2 = dy * 2.0f32 / 3.0f32;
            destination[cursor] = start; cursor += 1;
            destination[cursor] = Point { x: first_x, y: first_y }; cursor += 1;
            destination[cursor] = Point { x: peak_x, y: peak_y }; cursor += 1;
            destination[cursor] = Point { x: start.x + tx2, y: start.y + ty2 }; cursor += 1;
        }
        destination[cursor] = source[source_count - 1]; cursor += 1;
        source_count = cursor;
        std::mem::swap(&mut source, &mut destination);
    }
    for i in 0..result_points { *output.add(2*i) = source[i].x as f64; *output.add(2*i+1) = source[i].y as f64; }
    result_count as i64
}
