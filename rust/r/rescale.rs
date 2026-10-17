/// Return one unbiased discrete draw after rescaling the supplied range.
#[no_mangle]
pub unsafe extern "C" fn rescale(input: *const i64, length: usize) -> i64 {
    const MAX_DRAWS: i64 = 256;
    const MAX_INPUT_LENGTH: usize = 260;
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let max_value = values[0];
    let new_max = values[1];
    let draw_count = values[2];
    if !(2..=64).contains(&max_value) || !(1..=256).contains(&new_max)
        || !(1..=MAX_DRAWS).contains(&draw_count)
        || length != 3 + draw_count as usize { return -1; }
    let draws = &values[3..];
    if draws.iter().any(|&draw| draw < 0 || draw >= max_value) { return -1; }

    let mut cursor = 0usize;
    if new_max == max_value { return draws[0]; }

    if new_max < max_value {
        let threshold = max_value - max_value % new_max;
        while cursor < draws.len() {
            let draw = draws[cursor];
            cursor += 1;
            if draw < threshold { return draw % new_max; }
        }
        return -1;
    }

    let mut result = 0i64;
    let mut power = 1i64;
    while power < new_max {
        if cursor >= draws.len() { return -1; }
        result += power * draws[cursor];
        cursor += 1;
        power *= max_value;
    }
    if power == new_max { return result; }

    let threshold = power - power % new_max;
    while result >= threshold {
        result = 0;
        power = 1;
        while power < new_max {
            if cursor >= draws.len() { return -1; }
            result += power * draws[cursor];
            cursor += 1;
            power *= max_value;
        }
    }
    result % new_max
}
