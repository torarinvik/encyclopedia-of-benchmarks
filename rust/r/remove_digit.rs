const INVALID_RESULT: i64 = -1;
const MIN_VALID_INPUT: i64 = -9_223_372_036_854_775_807;

#[no_mangle]
pub extern "C" fn remove_digit(value: i64) -> i64 {
    if value < MIN_VALID_INPUT {
        return INVALID_RESULT;
    }
    let magnitude = if value < 0 { -value } else { value };
    if magnitude < 10 {
        return INVALID_RESULT;
    }
    let mut top_place = 1i64;
    while top_place <= magnitude / 10 {
        top_place *= 10;
    }
    let mut digit_count = 0i64;
    let mut place = top_place;
    while place > 0 {
        digit_count += 1;
        place /= 10;
    }
    let mut maximum = 0i64;
    for removed in 0..digit_count {
        let mut candidate = 0i64;
        let mut position = 0i64;
        place = top_place;
        while place > 0 {
            let digit = (magnitude / place) % 10;
            if position != removed {
                candidate = candidate * 10 + digit;
            }
            position += 1;
            place /= 10;
        }
        if candidate > maximum {
            maximum = candidate;
        }
    }
    maximum
}
