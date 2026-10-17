const MAX_INPUT_LENGTH: usize = 66;
const INVALID_RESULT: i64 = -1;

fn abs_i64(value: i64) -> i64 {
    if value < 0 { -value } else { value }
}

fn gcd_i64(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let temp = b;
        b = a % b;
        a = temp;
    }
    a
}

fn cross(x1: i64, y1: i64, x2: i64, y2: i64) -> i64 {
    x1 * y2 - x2 * y1
}

#[no_mangle]
pub unsafe extern "C" fn polygon_points(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_n = input[0];
    if !(3..=32).contains(&raw_n) || length != 1 + 2 * raw_n as usize { return INVALID_RESULT; }
    let n = raw_n as usize;
    if input[1..].iter().any(|&value| !(-1000..=1000).contains(&value)) { return INVALID_RESULT; }

    let origin_x = input[1];
    let origin_y = input[2];
    let mut doubled_area = 0i64;
    for i in 2..n {
        let x1 = input[1 + 2 * i] - origin_x;
        let y1 = input[2 + 2 * i] - origin_y;
        let x2 = input[1 + 2 * (i - 1)] - origin_x;
        let y2 = input[2 + 2 * (i - 1)] - origin_y;
        doubled_area += cross(x1, y1, x2, y2);
    }
    let area = abs_i64(doubled_area / 2);

    let mut boundary = raw_n;
    for i in 0..n {
        let next = (i + 1) % n;
        let dx = input[1 + 2 * i] - input[1 + 2 * next];
        let dy = input[2 + 2 * i] - input[2 + 2 * next];
        boundary += abs_i64(gcd_i64(dx, dy)) - 1;
    }
    area + 1 - boundary / 2
}
