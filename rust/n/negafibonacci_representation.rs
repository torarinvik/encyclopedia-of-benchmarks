const MAX_INDEX: usize = 17;
const VALUE_LIMIT: i64 = 1000;

fn encode(value: i64) -> ([u8; MAX_INDEX], usize) {
    let mut fib = [0i64; MAX_INDEX + 1];
    let mut weight = [0i64; MAX_INDEX + 1];
    let mut low = [0i64; MAX_INDEX + 1];
    let mut high = [0i64; MAX_INDEX + 1];
    let mut digit = [0u8; MAX_INDEX + 1];
    fib[1] = 1;
    fib[2] = 1;
    for k in 3..=MAX_INDEX { fib[k] = fib[k - 1] + fib[k - 2]; }
    for k in 1..=MAX_INDEX { weight[k] = if k % 2 == 1 { fib[k] } else { -fib[k] }; }
    for k in 1..=MAX_INDEX {
        let suffix_low = if k == 1 { 0 } else { low[k - 2] };
        let suffix_high = if k == 1 { 0 } else { high[k - 2] };
        low[k] = low[k - 1].min(weight[k] + suffix_low);
        high[k] = high[k - 1].max(weight[k] + suffix_high);
    }
    let mut remaining = value;
    let mut selected_above = false;
    for k in (1..=MAX_INDEX).rev() {
        let mut choose = false;
        if !selected_above {
            let suffix_low = if k == 1 { 0 } else { low[k - 2] };
            let suffix_high = if k == 1 { 0 } else { high[k - 2] };
            let candidate = remaining - weight[k];
            choose = suffix_low <= candidate && candidate <= suffix_high;
        }
        if choose { digit[k] = 1; remaining -= weight[k]; }
        selected_above = choose;
    }
    let mut highest = MAX_INDEX;
    while highest > 1 && digit[highest] == 0 { highest -= 1; }
    let mut output = [0u8; MAX_INDEX];
    let mut written = 0;
    for k in (1..=highest).rev() {
        output[written] = if digit[k] == 1 { b'1' } else { b'0' };
        written += 1;
    }
    (output, written)
}

#[no_mangle]
pub unsafe extern "C" fn negafibonacci_representation(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let value = values[0];
    if !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value) { return -1; }
    let (staged, required) = encode(value);
    if output.is_null() || output_capacity < required { return -2; }
    let buffer = std::slice::from_raw_parts_mut(output, required);
    buffer[..required].copy_from_slice(&staged[..required]);
    required as i64
}
