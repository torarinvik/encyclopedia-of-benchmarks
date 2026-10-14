const MAX_VALUES: usize = 256;
const MAX_INPUT_VALUES: usize = 1 + 2 * MAX_VALUES;
const NUMERATOR_LIMIT: i64 = 1_000_000_000_000;
const DENOMINATOR_LIMIT: i64 = 1_000_000;
const RESULT_OFFSET: i64 = 1_000_000_000_001;

fn ceil_division(numerator: i64, denominator: i64) -> i64 {
    if numerator >= 0 { numerator / denominator + i64::from(numerator % denominator != 0) }
    else { -((-numerator) / denominator) }
}

#[no_mangle]
pub unsafe extern "C" fn ceil_benchmark(values: *const i64, length: usize) -> i64 {
    if length < 1 || length > MAX_INPUT_VALUES { return -1; }
    let count_value = *values;
    if !(0..=MAX_VALUES as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 1 + 2 * count { return -1; }
    for i in 0..count {
        let numerator = *values.add(1 + 2 * i);
        let denominator = *values.add(2 + 2 * i);
        if numerator < -NUMERATOR_LIMIT || numerator > NUMERATOR_LIMIT ||
            denominator < 1 || denominator > DENOMINATOR_LIMIT { return -1; }
    }
    let mut checksum = 0i64;
    for i in 0..count {
        let result = ceil_division(*values.add(1 + 2 * i), *values.add(2 + 2 * i));
        checksum += (i as i64 + 1) * (result + RESULT_OFFSET);
    }
    checksum
}
