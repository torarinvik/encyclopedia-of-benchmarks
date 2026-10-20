const INPUT_LENGTH: usize = 7;
const MAX_OUTPUT_BYTES: usize = 152;
const COORDINATE_SCALE: i64 = 1_000_000;

fn orient(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64) -> i64 {
    (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}

fn round_ratio_away(numerator: i64, denominator: i64) -> i64 {
    let magnitude = if numerator < 0 { -numerator } else { numerator };
    let rounded = (magnitude + denominator / 2) / denominator;
    if numerator < 0 { -rounded } else { rounded }
}

fn put_i64(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn delaunay_mesh_refinement(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != INPUT_LENGTH || *values != 3 { return -1; }
    let mut x = [0i64; 3];
    let mut y = [0i64; 3];
    for i in 0..3 {
        x[i] = *values.add(1 + 2 * i);
        y[i] = *values.add(2 + 2 * i);
        if !(-100..=100).contains(&x[i]) || !(-100..=100).contains(&y[i]) { return -1; }
        for j in 0..i { if x[i] == x[j] && y[i] == y[j] { return -1; } }
    }
    let area2 = orient(x[0], y[0], x[1], y[1], x[2], y[2]);
    if area2 <= 0 { return -1; }
    for i in 0..3 {
        let j = (i + 1) % 3;
        let k = (i + 2) % 3;
        let ux = x[j] - x[i];
        let uy = y[j] - y[i];
        let vx = x[k] - x[i];
        let vy = y[k] - y[i];
        if ux * vx + uy * vy <= 0 { return -1; }
    }
    let len01 = (((x[1]-x[0])*(x[1]-x[0]) + (y[1]-y[0])*(y[1]-y[0])) as f64).sqrt();
    let len12 = (((x[2]-x[1])*(x[2]-x[1]) + (y[2]-y[1])*(y[2]-y[1])) as f64).sqrt();
    let len20 = (((x[0]-x[2])*(x[0]-x[2]) + (y[0]-y[2])*(y[0]-y[2])) as f64).sqrt();
    let shortest = len01.min(len12.min(len20));
    let ratio = len01 * len12 * len20 / (2.0 * area2 as f64 * shortest);
    let beta = 1.0 / (2.0 * (std::f64::consts::PI / 9.0).sin());
    let refine = ratio > beta * (1.0 + 1e-12);

    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    put_i64(&mut staged, 0, if refine { 4 } else { 3 });
    for i in 0..3 {
        put_i64(&mut staged, 8 + 16 * i, x[i] * COORDINATE_SCALE);
        put_i64(&mut staged, 16 + 16 * i, y[i] * COORDINATE_SCALE);
    }
    if refine {
        let ax = x[0];
        let ay = y[0];
        let bax = x[1] - ax;
        let bay = y[1] - ay;
        let cax = x[2] - ax;
        let cay = y[2] - ay;
        let denominator = 2 * (bax * cay - bay * cax);
        let balen_sq = bax * bax + bay * bay;
        let calen_sq = cax * cax + cay * cay;
        let center_x_num = ax * denominator + cay * balen_sq - bay * calen_sq;
        let center_y_num = ay * denominator + bax * calen_sq - cax * balen_sq;
        put_i64(&mut staged, 56, round_ratio_away(center_x_num * COORDINATE_SCALE, denominator));
        put_i64(&mut staged, 64, round_ratio_away(center_y_num * COORDINATE_SCALE, denominator));
        let words = [3, 0, 1, 3, 1, 2, 3, 2, 0, 3];
        for (i, word) in words.iter().enumerate() { put_i64(&mut staged, 72 + 8 * i, *word); }
    } else {
        let words = [1, 0, 1, 2];
        for (i, word) in words.iter().enumerate() { put_i64(&mut staged, 56 + 8 * i, *word); }
    }
    let required = if refine { MAX_OUTPUT_BYTES } else { 88 };
    if output.is_null() || capacity < required { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, required);
    required as i64
}
