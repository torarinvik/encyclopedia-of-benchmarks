const MAX_STAGE_COUNT: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STAGE_COUNT;

#[no_mangle]
pub unsafe extern "C" fn pipeline(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }

    let initial = *values;
    let stage_count = *values.add(1);
    if !(0..=2).contains(&initial) || !(1..=MAX_STAGE_COUNT as i64).contains(&stage_count) {
        return -1;
    }
    if length != 2 + 2 * stage_count as usize { return -1; }

    let mut result = initial;
    for index in 0..stage_count as usize {
        let operation = *values.add(2 + 2 * index);
        let argument = *values.add(3 + 2 * index);
        if !(0..=2).contains(&argument) { return -1; }
        match operation {
            0 => result += argument,
            1 => result *= argument,
            _ => return -1,
        }
    }
    result
}
