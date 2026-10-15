/// Find the least positive divisor whose rounded sum fits the threshold.
#[no_mangle]
pub extern "C" fn smallest_divisor(input: *const i64, length: usize) -> i64 {
    if !(2..=257).contains(&length) || input.is_null() {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let threshold = input[0];
    if !(1..=1_000_000).contains(&threshold) {
        return -1;
    }
    let mut maximum = 0i64;
    for &value in &input[1..] {
        if !(1..=1_000_000).contains(&value) {
            return -1;
        }
        maximum = maximum.max(value);
    }
    let count = (length - 1) as i64;
    if threshold < count {
        return -1;
    }
    let mut low = 1i64;
    let mut high = maximum;
    while low < high {
        let middle = low + (high - low) / 2;
        let sum: i64 = input[1..]
            .iter()
            .map(|&value| (value + middle - 1) / middle)
            .sum();
        if sum <= threshold {
            high = middle;
        } else {
            low = middle + 1;
        }
    }
    low
}
