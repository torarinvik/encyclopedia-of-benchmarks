/// Maximize one repeated binary answer while changing at most k entries.
const MAX_BITS: usize = 1024;

fn longest_for_target(values: &[i64], allowed: usize, target: i64) -> usize {
    let (mut left, mut opposite, mut best) = (0usize, 0usize, 0usize);
    for right in 0..values.len() {
        if values[right] != target { opposite += 1; }
        while opposite > allowed {
            if values[left] != target { opposite -= 1; }
            left += 1;
        }
        best = best.max(right - left + 1);
    }
    best
}

#[no_mangle]
pub extern "C" fn max_consecutive_answers(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_BITS + 1 { return -1; }
    let count = length - 1;
    let raw_allowed = unsafe { *input };
    if raw_allowed < 0 || raw_allowed as u128 > count as u128 { return -1; }
    let mut values = [0i64; MAX_BITS];
    for index in 0..count {
        let value = unsafe { *input.add(index + 1) };
        if value != 0 && value != 1 { return -1; }
        values[index] = value;
    }
    let bits = &values[..count];
    let allowed = raw_allowed as usize;
    longest_for_target(bits, allowed, 1).max(longest_for_target(bits, allowed, 0)) as i64
}
