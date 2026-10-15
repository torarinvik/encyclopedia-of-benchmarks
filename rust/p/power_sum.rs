/// Count distinct positive bases whose powers sum to the target.
fn search(target: i64, power: i64, base: i64, current_sum: i64) -> i64 {
    let mut term = 1_i64;
    for _ in 0..power {
        term *= base;
    }
    let new_sum = current_sum + term;
    if new_sum == target {
        return 1;
    }
    if new_sum > target {
        return 0;
    }
    search(target, power, base + 1, new_sum) + search(target, power, base + 1, current_sum)
}

#[no_mangle]
pub extern "C" fn power_sum(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length != 2 {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let target = packed[0];
    let power = packed[1];
    if !(1..=1000).contains(&target) || !(2..=10).contains(&power) {
        return -1;
    }
    search(target, power, 1, 0)
}
