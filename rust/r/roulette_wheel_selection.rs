const MAX_INPUT_VALUES: usize = 131;
const MAX_VALIDATORS: i64 = 128;
const MAX_STAKE: i64 = 1_000_000;
const MAX_TOTAL_STAKE: i64 = 128_000_000;

#[no_mangle]
pub unsafe extern "C" fn roulette_wheel_selection(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);

    let count_value = values[0];
    if !(1..=MAX_VALIDATORS).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 2 {
        return -1;
    }

    let mut total = 0i64;
    for index in 0..count {
        let stake = values[1 + index];
        if !(1..=MAX_STAKE).contains(&stake) {
            return -1;
        }
        if total > MAX_TOTAL_STAKE - stake {
            return -1;
        }
        total += stake;
    }

    let ticket = values[1 + count];
    if ticket < 0 || ticket >= total {
        return -1;
    }

    let mut cumulative = 0i64;
    for index in 0..count {
        cumulative += values[1 + index];
        if ticket < cumulative {
            return index as i64 + 1;
        }
    }
    -1
}
