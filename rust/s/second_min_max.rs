const INVALID_RESULT: i64 = i64::MIN;
const MAX_INPUT_LENGTH: usize = 259;
const INT32_MIN_VALUE: i64 = i32::MIN as i64;
const INT32_MAX_VALUE: i64 = i32::MAX as i64;

#[no_mangle]
pub unsafe extern "C" fn second_min_max(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT_LENGTH).contains(&length) { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let (operation, raw_count) = (values[0], values[1]);
    if (operation != 0 && operation != 1) || !(2..=256).contains(&raw_count) { return INVALID_RESULT; }
    let count = raw_count as usize;
    if length != count + 2 { return INVALID_RESULT; }
    let initial = if operation == 0 { INT32_MAX_VALUE } else { INT32_MIN_VALUE };
    let (mut best, mut second) = (initial, initial);
    for &value in &values[2..] {
        if value < INT32_MIN_VALUE || value > INT32_MAX_VALUE { return INVALID_RESULT; }
        let better = if operation == 0 { value < best } else { value > best };
        if better {
            second = best;
            best = value;
        } else {
            let improves_second = if operation == 0 { value < second } else { value > second };
            if improves_second && value != best { second = value; }
        }
    }
    if second == initial { INVALID_RESULT } else { second }
}
