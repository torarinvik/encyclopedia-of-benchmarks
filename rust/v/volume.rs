const INVALID_RESULT: i64 = -1;
const MAX_DIMENSION: i64 = 1000;

#[no_mangle]
pub extern "C" fn volume(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 4 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (operation, a, b, c) = (values[0], values[1], values[2], values[3]);
    if !(0..=MAX_DIMENSION).contains(&a)
        || !(0..=MAX_DIMENSION).contains(&b)
        || !(0..=MAX_DIMENSION).contains(&c) { return INVALID_RESULT; }
    match operation {
        0 => {
            if b != 0 || c != 0 { return INVALID_RESULT; }
            a * a * a
        }
        1 => a * b * c,
        2 => {
            let product = a * b * c;
            if product % 2 != 0 { return INVALID_RESULT; }
            product / 2
        }
        3 => {
            let product = a * b * c;
            if product % 3 != 0 { return INVALID_RESULT; }
            product / 3
        }
        _ => INVALID_RESULT,
    }
}
