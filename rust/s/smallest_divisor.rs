/// Find the least positive divisor whose rounded sum fits the threshold.
#[no_mangle]
pub extern "C" fn smallest_divisor(input: *const i64, length: usize) -> i64 {
    if !(2..=257).contains(&length) || input.is_null() {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let count = (length - 1) as u64;
    let threshold = input[0] as u64;
    if threshold < count || threshold > 1_000_000 { return -1; }
    let mut maximum = 0u64;
    let mut total = 0u64;
    for &value in &input[1..] {
        let value = value as u64;
        if value == 0 || value > 1_000_000 { return -1; }
        maximum = maximum.max(value);
        total += value;
    }
    if threshold == count { return maximum as i64; }

    let mut low = (total - 1) / threshold + 1;
    let upper_bound = (total - count) / (threshold - count + 1) + 1;
    let mut high = maximum.min(upper_bound);
    while low < high {
        let middle = low + ((high - low) >> 1);
        let mut rounded_sum = count;
        if count <= 4 {
            for &value in &input[1..] {
                rounded_sum += ((value as u32 - 1) / middle as u32) as u64;
            }
        } else {
            let reciprocal = (1_099_511_627_775 / middle) + 1;
            for &value in &input[1..] {
                rounded_sum += ((value as u64 - 1) * reciprocal) >> 40;
            }
        }
        if rounded_sum <= threshold { high = middle; }
        else { low = middle + 1; }
    }
    low as i64
}
