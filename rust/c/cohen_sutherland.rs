/// Selected coordinate or acceptance flag from Cohen-Sutherland clipping.
const INVALID_RESULT: f64 = -1.0e300;
const SCALE: f64 = 1_000_000.0;
const MAX_COORDINATE_MICRO: i64 = 1_000_000_000;
const INSIDE: i32 = 0;
const LEFT: i32 = 1;
const RIGHT: i32 = 2;
const BOTTOM: i32 = 4;
const TOP: i32 = 8;

fn region_code(x: f64, y: f64, x_min: f64, y_min: f64, x_max: f64, y_max: f64) -> i32 {
    let mut code = INSIDE;
    if x < x_min { code |= LEFT; } else if x > x_max { code |= RIGHT; }
    if y < y_min { code |= BOTTOM; } else if y > y_max { code |= TOP; }
    code
}

#[no_mangle]
pub extern "C" fn cohen_sutherland(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 9 { return INVALID_RESULT; }
    let v = unsafe { std::slice::from_raw_parts(values, length) };
    let selector = v[0];
    if !(0..=4).contains(&selector) { return INVALID_RESULT; }
    if v[1..].iter().any(|value| !(-MAX_COORDINATE_MICRO..=MAX_COORDINATE_MICRO).contains(value)) {
        return INVALID_RESULT;
    }
    let x_min = v[1] as f64 / SCALE;
    let y_min = v[2] as f64 / SCALE;
    let x_max = v[3] as f64 / SCALE;
    let y_max = v[4] as f64 / SCALE;
    if x_min >= x_max || y_min >= y_max { return INVALID_RESULT; }
    let mut x1 = v[5] as f64 / SCALE;
    let mut y1 = v[6] as f64 / SCALE;
    let mut x2 = v[7] as f64 / SCALE;
    let mut y2 = v[8] as f64 / SCALE;
    let mut code1 = region_code(x1, y1, x_min, y_min, x_max, y_max);
    let mut code2 = region_code(x2, y2, x_min, y_min, x_max, y_max);
    let mut accepted = false;
    loop {
        if code1 == INSIDE && code2 == INSIDE { accepted = true; break; }
        if code1 & code2 != 0 { break; }
        let code_out = if code1 != INSIDE { code1 } else { code2 };
        let (x, y) = if code_out & TOP != 0 {
            (x1 + (x2 - x1) * (y_max - y1) / (y2 - y1), y_max)
        } else if code_out & BOTTOM != 0 {
            (x1 + (x2 - x1) * (y_min - y1) / (y2 - y1), y_min)
        } else if code_out & RIGHT != 0 {
            (x_max, y1 + (y2 - y1) * (x_max - x1) / (x2 - x1))
        } else {
            (x_min, y1 + (y2 - y1) * (x_min - x1) / (x2 - x1))
        };
        if code_out == code1 {
            x1 = x; y1 = y;
            code1 = region_code(x1, y1, x_min, y_min, x_max, y_max);
        } else {
            x2 = x; y2 = y;
            code2 = region_code(x2, y2, x_min, y_min, x_max, y_max);
        }
    }
    if selector == 4 { return if accepted { 1.0 } else { 0.0 }; }
    if !accepted { return INVALID_RESULT; }
    match selector { 0 => x1, 1 => y1, 2 => x2, _ => y2 }
}
